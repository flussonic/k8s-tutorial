#!/usr/bin/env node

import util from 'util';
import mongo_pkg from 'mongodb';
import express from 'express';
import cors from 'cors';
import dns from 'dns';
import path from 'path';
import fs from 'fs';
const app = express();
const port = process.env.PORT || 3000;
const {MongoClient} = mongo_pkg;


const MONGO_URL = process.env['MONGO_URL'] || "mongodb://flus:sonic@mongo.default.svc.cluster.local:27017/flussonic";
const mongo_uri = new URL(MONGO_URL);

const client = await MongoClient.connect(MONGO_URL, { useNewUrlParser: true, useUnifiedTopology: true });
const db = client.db(mongo_uri.pathname.replace("/",""));
let streams = db.collection('streams');


function isObject(item) {
  return (item && typeof item === 'object' && !Array.isArray(item));
}

function mergeDeep(target, source) {
  let output = Object.assign({}, target);
  if (isObject(target) && isObject(source)) {
    Object.keys(source).forEach(key => {
      if (isObject(source[key])) {
        if (!(key in target))
          Object.assign(output, { [key]: source[key] });
        else
          output[key] = mergeDeep(target[key], source[key]);
      } else {
        Object.assign(output, { [key]: source[key] });
      }
    });
  }
  return output;
}


function log(object) {
  object.time = (new Date()).toISOString();
  console.log(JSON.stringify(object));
}

app.use(cors());
app.use(express.json());

app.use((err, req, res, next) => {
  console.error(err.stack)
  res.status(500).send('Something broke!')
});


app.get('/streamer/api/v3/ui_settings', (request, res) => {
  res.status(200).json({
    "colors": {
      "background": "#fff",
      "headerBackground": "#fff",
      "primary": "#4549F2",
      "secondary": "#E91E63"
    },
    menu_items: {
    }
  })
});


app.get('/streamer/api/v3/config', (req,res) => {
  res.status(200).json({})
})

app.get('/streamer/api/v3/system/updater', (req,res) => {
  res.status(200).json({status: "error"})
})

app.get('/streamer/api/v3/templates', async (req,res) => {
  res.status(200).json({templates: []})
})




// The managing part


app.get('/streamer/api/v3/streams', async (req,res) => {
  let response = {};

  if(!req.query.name) {
    response.streams = await streams.find({}).toArray();
  } else {
    const stream_names = req.query.name.split(",");
    response.streams = await streams.find({name: {'$in': stream_names}}).toArray();
  }
  res.status(200).json(response)
});


app.put('/streamer/api/v3/streams/:name', async (req,res) => {
  // const oldStream = await streams.findOne({name: req.params.name}) || {};
  // const newStream = mergeDeep(oldStream, req.body);
  // await streams.updateOne({name: req.params.name}, {$set: newStream}, {upsert: true});
  const stream = await streams.findOne({name: req.params.name});
  postprocess(stream);
  res.status(200).json(stream)
})

app.delete('/streamer/api/v3/streams/:name', async (req,res) => {
  // await streams.deleteOne({name: req.params.name});
  res.status(204)
})

app.get('/streamer/api/v3/streams/:name', async (req,res) => {
  const stream = await streams.findOne({name: req.params.name}) || {};
  postprocess(stream);
  if(stream === null)
    res.status(404).json({error: "enoent"})
  else
    res.status(200).json(stream)
});



function postprocess(stream) {
  stream.config_on_disk = mergeDeep({}, stream);
  stream.named_by = "config";
  if(! ('static' in stream)) {
    stream.static = true;
  }
}


async function gethostsbyname(hostname) {
  return new Promise((resolve, reject) => {
    dns.resolve(hostname, "A", (err, addresses, family) => {
      if(err) reject(err);
      resolve(addresses);
    });
  });
};


async function fetchTranscoders() {
  if(process.env.KUBERNETES_SERVICE_HOST) {
    return await gethostsbyname("transcoder.default.svc.cluster.local");
  } else {
    return ["127.0.0.1:8085"];
  }
}

function hashCode(str) {
  let hash = 0;
  for (let i = 0, len = str.length; i < len; i++) {
    let chr = str.charCodeAt(i);
    hash = (hash << 5) - hash + chr;
    hash |= 0; // Convert to 32bit integer
  }
  return hash;
}

// The serving part

app.get('/publish/streams', async (req,res) => {
  if(!req.query.name) {
    res.status(200).json({streams: []});
    log({konfig: 'publish', name: null, code: 200});
    return;
  }
  if(!req.query.client_host) {
    res.status(400).json({status: "must_provide_client_host"});
    log({konfig: 'publish', status: "must_provide_client_host", code: 400});
    return;
  }

  const stream_names = req.query.name.split(",");

  const existing_streams = await streams.find({
    "pipeline.publish": req.query.client_host,
  }).toArray();

  const streams_to_delete = existing_streams.filter((s) => {
    return !stream_names.find(name => s.name == name);    
  }).map(s => s.name);

  if(streams_to_delete.length > 0) {
    await streams.deleteMany({name: {'$in': streams_to_delete}});  
  }

  const new_stream_names = stream_names.filter((name) => {
    return !existing_streams.find(s => s.name == name);
  });

  const transcoders = new_stream_names.length > 0 ? await fetchTranscoders() : [];

  new_stream_names.forEach(async (name) => {
      let stream_config = {
      name: name,
      pipeline: {
        publish: req.query.client_host,
      }
    }
    if(transcoders.length > 0) {
      stream_config.pipeline.transcoder = transcoders[hashCode(name) % transcoders.length];
    }
    await streams.updateOne({name: name}, {$set: stream_config}, {upsert: true});
  });

  const new_streams = await streams.find({name: {'$in': new_stream_names}}).toArray();
  
  const response_streams = (await streams.find({"pipeline.publish": req.query.client_host}).toArray()).map((s) => {
    s.inputs = [{url: "publish://"}];
    if(s.pipeline.transcoder) {
      s.pushes = [{url: `m4s://${s.pipeline.transcoder}/${s.name}`}];      
    }
    delete s._id;
    delete s.pipeline;
    return s;
  })
  let response = {streams: response_streams};
  res.status(200).json(response)
  log({konfig: 'publish', new: new_stream_names.length, deleted: streams_to_delete.length, 
    server: req.query.client_host, streams: response_streams.length, code: 200});
});


app.get('/transcoder/streams', async (req,res) => {
  if(!req.query.name) {
    res.status(200).json({streams: []});
    return;
  }
  const query = {name: {'$in': req.query.name.split(",")}};
  const response_streams = (await streams.find(query).toArray()).map((s) => {
    s.inputs = [{url: "publish://"}];
    // s.transcoder = {}; ...
    delete s._id;
    delete s.pipeline;
    return s;
  })
  let response = {streams: response_streams};
  res.status(200).json(response)

  log({konfig: 'transcoder', server: req.query.client_host, streams: response_streams.length});
});



app.get('/restreamer/streams', async (req,res) => {
  if(!req.query.name) {
    res.status(200).json({streams: []});
    return;
  }
  // if(!req.query.client_host) {
  //   res.status(400).json({code: "must_provide_client_host"});
  //   return;
  // }

  const stream_names = req.query.name.split(",");

  const response_streams = (await streams.find({name: {'$in': stream_names}}).toArray()).map((s) => {
    s.inputs = [{url: `m4f://${s.pipeline.transcoder}/${s.name}`}];
    s.static = false;
    delete s._id;
    delete s.pipeline;
    return s;
  })
  let response = {streams: response_streams};
  res.status(200).json(response)
  log({konfig: 'restreamer', server: req.query.client_host, streams: response_streams.length});
});

// app.get('*',(req, res) => {
//   console.log(req.path);
//   res.status(404).json({error: "not_implemented"})
// });



app.listen(port, () => {
  log({service: 'running', port: port});
})
