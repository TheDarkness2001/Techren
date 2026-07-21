const mongoose = require('mongoose');
const dns = require('dns');
const config = require('./index');
const logger = require('./logger');

let memoryServer;
let connectionMode = 'unknown';

const configureAtlasDns = () => {
  if (!config.isAtlasUri) return;

  // Windows/corporate DNS often returns querySrv ECONNREFUSED for MongoDB Atlas SRV records.
  // Public resolvers reliably resolve _mongodb._tcp.*.mongodb.net.
  const servers = (process.env.MONGO_DNS_SERVERS || '8.8.8.8,1.1.1.1')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);

  if (servers.length > 0) {
    dns.setServers(servers);
    logger.info(`MongoDB Atlas DNS resolvers: ${servers.join(', ')}`);
  }
};

const connectDB = async () => {
  try {
    configureAtlasDns();
    const conn = await mongoose.connect(config.mongoUri);
    connectionMode = config.isAtlasUri ? 'atlas' : 'remote';
    logger.info(`MongoDB connected: ${conn.connection.host} [${connectionMode}]`);
    return conn;
  } catch (error) {
    if (!config.useMemoryFallback) {
      logger.error(`MongoDB connection error: ${error.message}`);
      if (config.isAtlasUri) {
        logger.error('Atlas connection failed. Check MONGO_URI, database user password, and Network Access IP whitelist.');
      }
      process.exit(1);
    }

    logger.warn(`MongoDB unavailable (${error.message}). Starting in-memory database for development.`);
    const { MongoMemoryServer } = require('mongodb-memory-server');
    memoryServer = await MongoMemoryServer.create();
    const uri = memoryServer.getUri();
    const conn = await mongoose.connect(uri);
    connectionMode = 'memory';
    logger.info('In-memory MongoDB connected');
    return conn;
  }
};

const getConnectionInfo = () => {
  const { connection } = mongoose;
  // Production health should not leak host/db names.
  if (!config.isDev) {
    return {
      mode: connectionMode === 'memory' ? 'fallback' : (connection.readyState === 1 ? 'connected' : 'disconnected'),
      readyState: connection.readyState,
    };
  }
  return {
    mode: connectionMode,
    readyState: connection.readyState,
    host: connection.host || null,
    name: connection.name || null,
    isAtlas: config.isAtlasUri,
  };
};

const disconnectDB = async () => {
  await mongoose.disconnect();
  connectionMode = 'unknown';
  if (memoryServer) {
    await memoryServer.stop();
    memoryServer = null;
  }
};

module.exports = connectDB;
module.exports.disconnectDB = disconnectDB;
module.exports.getConnectionInfo = getConnectionInfo;
module.exports.configureAtlasDns = configureAtlasDns;
