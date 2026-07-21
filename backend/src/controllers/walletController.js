const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const walletService = require('../services/walletService');

const handle = (res, e) => sendError(res, e.statusCode || 500, e.code || 'SERVER_ERROR', e.message);

exports.balance = asyncHandler(async (req, res) => {
  try {
    const data = await walletService.getBalance(req);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.transactions = asyncHandler(async (req, res) => {
  try {
    const data = await walletService.listTransactions(req);
    sendSuccess(res, data);
  } catch (e) {
    handle(res, e);
  }
});

exports.topup = asyncHandler(async (req, res) => {
  try {
    const data = await walletService.topup(req, req.body);
    sendSuccess(res, data, 201);
  } catch (e) {
    handle(res, e);
  }
});

exports.deduct = asyncHandler(async (req, res) => {
  try {
    const data = await walletService.deduct(req, req.body);
    sendSuccess(res, data, 201);
  } catch (e) {
    handle(res, e);
  }
});
