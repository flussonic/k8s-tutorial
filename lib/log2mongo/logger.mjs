#!/usr/bin/env node
// vim: set tabstop=2 softtabstop=2 shiftwidth=2 expandtab 


import chokidar from 'chokidar';
import mongo_pkg from 'mongodb';
import os from 'os';
import path from 'path';
import {globby} from 'globby';
import fs from 'fs/promises';
import { Buffer } from 'node:buffer';
import util from 'util';

const {MongoClient} = mongo_pkg;

const MONGO_URL = process.env['MONGO_URL'] || "mongodb://flus:sonic@mongo.default.svc.cluster.local:27017/logging";
const LOG_DIR = process.env['LOG_DIR'] || "/var/log/containers";
const POLL_DELAY = (process.env['POLL_DELAY'] ? parseInt(process.env['POLL_DELAY']) : 0) || 5000;

//console.log(`mongo_url: ${MONGO_URL}`);
//console.log(`log_dir: ${LOG_DIR}`);

const client = await MongoClient.connect(MONGO_URL, { useNewUrlParser: true, useUnifiedTopology: true });
const db = client.db("logging");
let log_entries = db.collection('flussonic');

if (process.env['MONGO_SIZE_LIMIT']) {
  db.runCommand({convertToCapped: "flussonic", size: parseInt(process.env['MONGO_SIZE_LIMIT'])});
  db.runCommand({collMod: "flussonic", cappedSize: parseInt(process.env['MONGO_SIZE_LIMIT'])});
}

let log_offsets = db.collection('log_offsets');

//await collection.insertOne({startup: true});

let file_offsets = {};
let fds = {};
let read_buffer = Buffer.alloc(1024*1024);



async function copyAll(log_dir) {
  let log_files = await globby(`${log_dir}/flussonic*log`);
  for (const p of log_files) {
    //console.log(`tail: ${p}`);
    let rows = await tail(p);
    if (rows.length > 0) {
      const x = await log_entries.insertMany(rows);
      console.log(`save offset ${p} ${file_offsets[p]}`);
      await log_offsets.updateOne({path: p}, {$set: {path: p, offset: file_offsets[p]}}, { upsert: true });
    }
  }
  for (const p in fds) {
    if (log_files.indexOf(p) == -1) {
      await fds[log_path].close();
      await log_offsets.deleteOne({path: p})
      console.log(`close deleted ${p}`);
    }
  }
}

async function tail(log_path) {
  if (!fds[log_path]) {
    console.log(`open log ${log_path}`);
    fds[log_path] = await fs.open(`${log_path}`, "r");
  }
  if (!file_offsets[log_path]) {
    const old_offset = await log_offsets.findOne({path: log_path});
    //console.log(`restore ${old_offset.offset}`);
    file_offsets[log_path] = old_offset ? old_offset.offset : 0;
  }
  const name_parts = path.basename(log_path,'.log').split("_");
  let rows = [];
  while (true) {
    let bytes = await fds[log_path].read(read_buffer, 0, read_buffer.length, file_offsets[log_path]);
    //console.log(`prefill buffer from ${file_offsets[log_path]}: ${bytes.bytesRead}`);
    if (bytes.bytesRead == 0) break;
    let start_pos = 0;
    let end_pos = 0;
    while (true) {
      end_pos = read_buffer.indexOf('\n', start_pos);
      if (end_pos == -1) break;
      let row = read_buffer.subarray(start_pos, end_pos-start_pos).toString('utf8');
      let rowlog = JSON.parse(row);
      if(rowlog.log.length > 10 && rowlog.log[0] == '{') {
        let nested_log = JSON.parse(rowlog.log);
        //console.log(`${util.inspect(nested_log)}`);
        nested_log['k8s_pod'] = name_parts[0];
        nested_log['k8s_namespace'] = name_parts[1];
        nested_log['k8s_container'] = name_parts[2];
	if(nested_log.time) {
	  nested_log.time = new Date(nested_log.time);
        }
        rows.push(nested_log);
      }
      //console.log(`${start_pos}..${end_pos} ${row.length}: '${row}'`);
      //console.log(`consume ${file_offsets[log_path]} + ${start_pos} .. ${end_pos - start_pos}`);
      start_pos = end_pos + 1;
      break;
    }
    //console.log(`consumed all buffer, read ${start_pos} bytes from it`);
    if (!start_pos) break;
    file_offsets[log_path] += start_pos;
  }
  console.log(`read from ${log_path} ${rows.length} rows`);
  return rows;
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

await copyAll(LOG_DIR);

while(true) {
  await copyAll(LOG_DIR);
//  console.log(`sleep`);
  await sleep(5000);
}

//chokidar.watch(LOG_DIR).on('all', (e,p,s) => {
//  await copyAll(LOG_DIR);
//})

