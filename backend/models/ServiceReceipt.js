const mongoose = require("mongoose");

const serviceReceiptSchema = new mongoose.Schema(
  {
    vehicleNumber: { type: String, index: true },
    previousOilChange: String,
    currentMileage: String,
    nextServiceDate: String,
    services: { type: Map, of: String, default: {} },
    status: {
      type: String,
      enum: ["not confirmed", "confirmed", "rejected", "finished", "done"],
      default: "not confirmed",
      index: true,
    },
    serviceCenterId: { type: String, index: true },
    "Service Center Name": String,
  },
  { timestamps: true }
);

module.exports = mongoose.model("ServiceReceipt", serviceReceiptSchema);
