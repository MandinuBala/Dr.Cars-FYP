const mongoose = require('mongoose');

const vehicleDocumentSchema = new mongoose.Schema({
  userId:         { type: String, required: true },
  type:           { type: String, enum: ['license', 'insurance'], required: true },
  label:          { type: String, required: true },
  documentNumber: { type: String, default: '' },
  vehiclePlate:   { type: String, default: '' },
  issueDate:      { type: Date },
  expiryDate:     { type: Date, required: true },
  photoUrl:       { type: String, default: '' },
  createdAt:      { type: Date, default: Date.now },
});

module.exports = mongoose.model('VehicleDocument', vehicleDocumentSchema);