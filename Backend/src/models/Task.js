const mongoose = require("mongoose");

const taskSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true
  },

  title: {
    type: String,
    required: true
  },

  estimatedTime: {
    type: Number, // in minutes
    required: true
  },

  actualTime: {
    type: Number // filled later
  },

  deadline: {
    type: Date
  },

  status: {
    type: String,
    enum: ["pending", "completed", "missed"],
    default: "pending"
  },

  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model("Task", taskSchema);
