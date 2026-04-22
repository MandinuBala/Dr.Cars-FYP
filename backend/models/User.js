const mongoose = require("mongoose");

const userSchema = new mongoose.Schema({
  uid: String,
  name: String,
  serviceCenterName: String,
  email: { type: String, unique: true },
  username: { type: String, sparse: true },
  password: String,
  address: String,
  contact: String,
  city: String,
  branch: String,
  userType: String,
  googleId: { type: String, sparse: true },
  facebookId: { type: String, sparse: true },
  photoUrl: String,
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model("User", userSchema);