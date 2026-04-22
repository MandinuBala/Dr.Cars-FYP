const mongoose = require("mongoose");

const vehicleSchema = new mongoose.Schema({
  userId: {
    type: String,
    required: true,
    index: true
  },
  uid: {
    type: String,
    index: true,
  },
  brand: {
    type: String,
    default: ""
  },
  model: {
    type: String,
    default: ""
  },
  year: {
    type: Number
  },
  plateNumber: {
    type: String,
    default: ""
  },
  vehicleNumber: {
    type: String,
    index: true,
  },
  selectedBrand: String,
  selectedModel: String,
  vehicleType: String,
  mileage: String,
  vehiclePhotoUrl: String,
}, { timestamps: true });

module.exports = mongoose.model("Vehicle", vehicleSchema);
