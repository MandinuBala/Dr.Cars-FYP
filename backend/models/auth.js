// auth.js
const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
require("dotenv").config();

const User = require("./models/User");
const Vehicle = require("./models/vehicle");
const verifyToken = require("./middleware/middleware");

const app = express();
app.use(cors());
app.use(express.json());

// ---------------- RESET PASSWORD ----------------
router.post("/reset-password", async (req, res) => {
  try {
    const { input } = req.body;

    // ✅ Validate input
    if (!input) {
      return res.status(400).json({
        message: "Email or username is required",
      });
    }

    // 🔍 Find user by email OR username
    const user = await User.findOne({
      $or: [{ email: input }, { username: input }],
    });

    if (!user) {
      return res.status(404).json({
        message: "User not found",
      });
    }

    // 🔑 Generate temporary password
    const tempPassword = Math.random().toString(36).slice(-8);

    // 🔐 Hash password
    const hashedPassword = await bcrypt.hash(tempPassword, 10);

    // 💾 Save new password
    user.password = hashedPassword;
    await user.save();

    // ✅ Send response (Flutter will receive this)
    res.status(200).json({
      message: "Password reset successful",
      tempPassword: tempPassword, // ⚠️ for testing only
    });

  } catch (error) {
    console.error("Reset password error:", error);
    res.status(500).json({
      message: "Server error",
    });
  }
});

// ---------------------- MONGODB CONNECTION ----------------------
mongoose
  .connect(process.env.MONGO_URI)
  .then(() => console.log("MongoDB Connected"))
  .catch((err) => console.log("MongoDB connection error:", err));

// ---------------------- HOME ROUTE ----------------------
app.get("/", (req, res) => {
  res.send("Dr.Cars Backend Running");
});

// ---------------------- REGISTER ----------------------
app.post("/register", async (req, res) => {
  try {
    const { name, email, password, userType } = req.body;

    const existingUser = await User.findOne({ email });
    if (existingUser) return res.status(400).json({ message: "User already exists" });

    const hashedPassword = await bcrypt.hash(password, 10);

    const newUser = await User.create({
      name,
      email,
      password: hashedPassword,
      userType: userType || "Vehicle Owner",
      createdAt: new Date(),
    });

    res.status(201).json({ user: newUser });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// ---------------------- LOGIN ----------------------
app.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email });
    if (!user) return res.status(400).json({ message: "User not found" });

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(400).json({ message: "Invalid credentials" });

    const token = jwt.sign(
      { id: user._id, email: user.email, userType: user.userType },
      process.env.JWT_SECRET,
      { expiresIn: "7d" }
    );

    res.json({ user, token });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// ---------------------- GOOGLE LINK ----------------------
app.post("/google/link", async (req, res) => {
  try {
    const { email, googleId, password, userType } = req.body;

    let user = await User.findOne({ email });

    if (user) {
      // update existing
      user.googleId = googleId;
      user.password = await bcrypt.hash(password, 10);
      await user.save();
    } else {
      // create new
      user = await User.create({
        email,
        googleId,
        password: await bcrypt.hash(password, 10),
        userType: userType || "Vehicle Owner",
        createdAt: new Date(),
      });
    }

    const token = jwt.sign(
      { id: user._id, email: user.email, userType: user.userType },
      process.env.JWT_SECRET,
      { expiresIn: "7d" }
    );

    res.json({ user, token });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// ---------------------- GOOGLE PROFILE COMPLETION ----------------------
app.post("/google/complete", async (req, res) => {
  try {
    const { uid, name, email, username, password, address, contact } = req.body;

    const exists = await User.findOne({ username });
    if (exists) return res.status(400).json({ message: "Username taken" });

    const hashedPassword = await bcrypt.hash(password, 10);

    const user = await User.create({
      uid,
      name,
      email,
      username,
      password: hashedPassword,
      address,
      contact,
      userType: "Vehicle Owner",
      createdAt: new Date(),
    });

    const token = jwt.sign(
      { id: user._id, email: user.email, userType: user.userType },
      process.env.JWT_SECRET,
      { expiresIn: "7d" }
    );

    res.json({ user, token });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// ---------------------- ADD VEHICLE ----------------------
app.post("/vehicles", async (req, res) => {
  try {
    const { userId, brand, model, year, plateNumber } = req.body;

    const newVehicle = await Vehicle.create({
      userId,
      brand,
      model,
      year,
      plateNumber,
    });

    res.status(201).json(newVehicle);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// ---------------------- LOGOUT (JWT-protected) ----------------------
app.post("/logout", verifyToken, (req, res) => {
  res.json({ message: "Logged out successfully" });
});

// ---------------------- START SERVER ----------------------
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
