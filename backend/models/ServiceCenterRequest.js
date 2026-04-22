const mongoose = require("mongoose");

const serviceCenterRequestSchema = new mongoose.Schema(
  {
    email: { type: String, index: true },
    username: { type: String, index: true },
    passwordHash: { type: String, select: false },
    status: {
      type: String,
      enum: ["pending", "accepted", "rejected"],
      default: "pending",
      index: true,
    },
    serviceCenterName: String,
    ownerName: String,
    nic: String,
    regNumber: String,
    address: String,
    contact: String,
    notes: String,
    city: String,
  },
  { timestamps: true }
);

module.exports = mongoose.model("ServiceCenterRequest", serviceCenterRequestSchema);
