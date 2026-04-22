const mongoose = require("mongoose");

const feedbackSchema = new mongoose.Schema(
  {
    serviceCenterId: { type: String, index: true },
    userId: String,
    name: String,
    rating: Number,
    feedback: String,
    date: String,
  },
  { timestamps: true }
);

module.exports = mongoose.model("Feedback", feedbackSchema);
