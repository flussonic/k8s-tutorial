#!/usr/bin/env node

import mongo_pkg from 'mongodb';
const {MongoClient} = mongo_pkg;
import util from 'util';


const MONGO_URL = process.env['MONGO_URL'] || "mongodb://flus:sonic@mongo.default.svc.cluster.local:27017/logging";
const client = await MongoClient.connect(MONGO_URL, { useNewUrlParser: true, useUnifiedTopology: true });

const db = client.db("logging");
let log_entries = db.collection('flussonic');
let filter = {};

let seekCursor = await log_entries.find(filter).sort({$natural: -1}).limit(1);
if (seekCursor.length > 0)
  filter.time = {$gte: seekCursor[0].time};

let cursor = log_entries.find(filter,{tailable: true}).stream();

cursor.on('data', (e) => {
  console.log(util.inspect(e));
});



