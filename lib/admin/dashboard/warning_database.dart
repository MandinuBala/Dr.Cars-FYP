// lib/admin/dashboard/warning_database.dart
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WARNING INFO MODEL
// ─────────────────────────────────────────────────────────────────────────────
class WarningInfo {
  final String title;
  final String severity; // 'critical' | 'serious' | 'moderate' | 'info'
  final String description;
  final List<String> driverActions;
  final List<String> diySteps;
  final bool isDIYFixable;
  final String youtubeQuery;

  const WarningInfo({
    required this.title,
    required this.severity,
    required this.description,
    required this.driverActions,
    required this.diySteps,
    required this.isDIYFixable,
    required this.youtubeQuery,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// DATABASE
// ─────────────────────────────────────────────────────────────────────────────
class WarningDatabase {
  // ── Brand → indicator image paths ─────────────────────────────────────────
  // BMW and Toyota use their own brand assets.
  // All other brands reuse Toyota images as universal references.
  static const Map<String, List<String>> brandIndicatorSets = {
    'BMW': [
      'images/BMW/check engine.png',
      'images/BMW/fuel low.png',
      'images/BMW/oil light.png',
      'images/BMW/high heat.png',
      'images/BMW/tire presure waring.png',
      'images/BMW/breake.png',
      'images/BMW/ABS.png',
      'images/BMW/seatbelt.png',
      'images/BMW/123.png',
      'images/BMW/airbag waring.png',
      'images/BMW/e brake.png',
      'images/BMW/fog lights.png',
      'images/BMW/glow.png',
      'images/BMW/TRC.png',
      'images/BMW/warning.png',
      'images/BMW/window heater.png',
    ],
    'Toyota': [
      'images/Toyota/ENGINE CHECK LIGHT.png',
      'images/Toyota/LOW FUEL.png',
      'images/Toyota/WATER HEAT.png',
      'images/Toyota/BATTERY CHECK.png',
      'images/Toyota/HAND BREAK.png',
      'images/Toyota/seat bealts.png',
      'images/Toyota/ABS.png',
      'images/Toyota/DOORS OPEND.png',
      'images/Toyota/HAZARD.png',
      'images/Toyota/HEAD BEAM.png',
      'images/Toyota/LOW BEAM.png',
      'images/Toyota/WINDSCREEN WASHER LIQUID LOW.png',
    ],
    // All other brands reuse Toyota images as universal indicators
    'Nissan': [
      'images/Toyota/ENGINE CHECK LIGHT.png',
      'images/Toyota/LOW FUEL.png',
      'images/Toyota/WATER HEAT.png',
      'images/Toyota/BATTERY CHECK.png',
      'images/Toyota/HAND BREAK.png',
      'images/Toyota/seat bealts.png',
      'images/Toyota/ABS.png',
      'images/Toyota/DOORS OPEND.png',
      'images/Toyota/HAZARD.png',
      'images/Toyota/HEAD BEAM.png',
      'images/Toyota/LOW BEAM.png',
      'images/Toyota/WINDSCREEN WASHER LIQUID LOW.png',
    ],
    'Honda': [
      'images/Toyota/ENGINE CHECK LIGHT.png',
      'images/Toyota/LOW FUEL.png',
      'images/Toyota/WATER HEAT.png',
      'images/Toyota/BATTERY CHECK.png',
      'images/Toyota/HAND BREAK.png',
      'images/Toyota/seat bealts.png',
      'images/Toyota/ABS.png',
      'images/Toyota/DOORS OPEND.png',
      'images/Toyota/HAZARD.png',
      'images/Toyota/HEAD BEAM.png',
      'images/Toyota/LOW BEAM.png',
      'images/Toyota/WINDSCREEN WASHER LIQUID LOW.png',
    ],
    'Suzuki': [
      'images/Toyota/ENGINE CHECK LIGHT.png',
      'images/Toyota/LOW FUEL.png',
      'images/Toyota/WATER HEAT.png',
      'images/Toyota/BATTERY CHECK.png',
      'images/Toyota/HAND BREAK.png',
      'images/Toyota/seat bealts.png',
      'images/Toyota/ABS.png',
      'images/Toyota/DOORS OPEND.png',
      'images/Toyota/HAZARD.png',
      'images/Toyota/HEAD BEAM.png',
      'images/Toyota/LOW BEAM.png',
      'images/Toyota/WINDSCREEN WASHER LIQUID LOW.png',
    ],
    'Mazda': [
      'images/Toyota/ENGINE CHECK LIGHT.png',
      'images/Toyota/LOW FUEL.png',
      'images/Toyota/WATER HEAT.png',
      'images/Toyota/BATTERY CHECK.png',
      'images/Toyota/HAND BREAK.png',
      'images/Toyota/seat bealts.png',
      'images/Toyota/ABS.png',
      'images/Toyota/DOORS OPEND.png',
      'images/Toyota/HAZARD.png',
      'images/Toyota/HEAD BEAM.png',
      'images/Toyota/LOW BEAM.png',
      'images/Toyota/WINDSCREEN WASHER LIQUID LOW.png',
    ],
    'Kia': [
      'images/Toyota/ENGINE CHECK LIGHT.png',
      'images/Toyota/LOW FUEL.png',
      'images/Toyota/WATER HEAT.png',
      'images/Toyota/BATTERY CHECK.png',
      'images/Toyota/HAND BREAK.png',
      'images/Toyota/seat bealts.png',
      'images/Toyota/ABS.png',
      'images/Toyota/DOORS OPEND.png',
      'images/Toyota/HAZARD.png',
      'images/Toyota/HEAD BEAM.png',
      'images/Toyota/LOW BEAM.png',
      'images/Toyota/WINDSCREEN WASHER LIQUID LOW.png',
    ],
    'Hyundai': [
      'images/Toyota/ENGINE CHECK LIGHT.png',
      'images/Toyota/LOW FUEL.png',
      'images/Toyota/WATER HEAT.png',
      'images/Toyota/BATTERY CHECK.png',
      'images/Toyota/HAND BREAK.png',
      'images/Toyota/seat bealts.png',
      'images/Toyota/ABS.png',
      'images/Toyota/DOORS OPEND.png',
      'images/Toyota/HAZARD.png',
      'images/Toyota/HEAD BEAM.png',
      'images/Toyota/LOW BEAM.png',
      'images/Toyota/WINDSCREEN WASHER LIQUID LOW.png',
    ],
  };

  // ── Image path → display title ─────────────────────────────────────────────
  static const Map<String, String> indicatorTitles = {
    // BMW
    'images/BMW/check engine.png': 'Check Engine',
    'images/BMW/fuel low.png': 'Low Fuel',
    'images/BMW/oil light.png': 'Low Oil Pressure',
    'images/BMW/high heat.png': 'Engine Overheating',
    'images/BMW/tire presure waring.png': 'Tyre Pressure',
    'images/BMW/breake.png': 'Brake System',
    'images/BMW/ABS.png': 'ABS Warning',
    'images/BMW/seatbelt.png': 'Seatbelt Reminder',
    'images/BMW/123.png': 'Battery / Charging',
    'images/BMW/airbag waring.png': 'Airbag / SRS',
    'images/BMW/e brake.png': 'Parking Brake',
    'images/BMW/fog lights.png': 'Fog Lights',
    'images/BMW/glow.png': 'Glow Plugs',
    'images/BMW/TRC.png': 'Traction Control',
    'images/BMW/warning.png': 'General Warning',
    'images/BMW/window heater.png': 'Rear Defroster',
    // Toyota / Universal
    'images/Toyota/ENGINE CHECK LIGHT.png': 'Check Engine',
    'images/Toyota/LOW FUEL.png': 'Low Fuel',
    'images/Toyota/WATER HEAT.png': 'Engine Overheating',
    'images/Toyota/BATTERY CHECK.png': 'Battery / Charging',
    'images/Toyota/HAND BREAK.png': 'Parking Brake',
    'images/Toyota/seat bealts.png': 'Seatbelt Reminder',
    'images/Toyota/ABS.png': 'ABS Warning',
    'images/Toyota/DOORS OPEND.png': 'Door Ajar',
    'images/Toyota/HAZARD.png': 'Hazard Lights',
    'images/Toyota/HEAD BEAM.png': 'High Beam',
    'images/Toyota/LOW BEAM.png': 'Low Beam',
    'images/Toyota/WINDSCREEN WASHER LIQUID LOW.png': 'Washer Fluid Low',
  };

  // ── Full warning details ───────────────────────────────────────────────────
  static const Map<String, WarningInfo> warnings = {
    // ══════════════════════════════════════════════════════════════
    // BMW INDICATORS
    // ══════════════════════════════════════════════════════════════
    'images/BMW/check engine.png': WarningInfo(
      title: 'Check Engine (MIL)',
      severity: 'serious',
      description:
          'The engine management system has detected a fault in the engine or '
          'emissions system. Could be anything from a loose fuel cap to a '
          'faulty oxygen sensor, catalytic converter, or spark plug. '
          'A flashing light means a serious misfire — act immediately.',
      driverActions: [
        'If the light is FLASHING — reduce speed immediately, avoid high RPM, and pull over safely.',
        'If the light is STEADY — drive normally but get the car scanned soon.',
        'First check: tighten the fuel cap fully.',
        'Avoid heavy loads or towing until the issue is resolved.',
      ],
      diySteps: [
        'Check the fuel cap — turn it clockwise until it clicks. A loose cap is the #1 cause.',
        'Drive 3–4 km and see if the light turns off on its own.',
        'Connect an OBD2 scanner to the diagnostic port (under the dashboard, driver side).',
        'Note the fault code (e.g. P0420, P0300).',
        'Search the exact code on YouTube or Google for your specific car model.',
        'Common DIY fixes: replace oxygen sensor, clean MAF sensor, replace spark plugs.',
        'If unsure, take it to a mechanic with the code already read.',
      ],
      isDIYFixable: true,
      youtubeQuery: 'BMW check engine light common causes and how to fix',
    ),

    'images/BMW/fuel low.png': WarningInfo(
      title: 'Low Fuel Warning',
      severity: 'moderate',
      description:
          'Your fuel level is critically low — typically under 10–15 km of '
          'range remaining. Running the tank completely dry can damage your '
          'fuel pump and fuel injectors, leading to expensive repairs.',
      driverActions: [
        'Head to the nearest petrol station immediately.',
        'Reduce speed to conserve remaining fuel.',
        'Turn off the air conditioning to save fuel.',
        'Avoid sharp acceleration.',
      ],
      diySteps: [
        'Drive at a steady 60–80 km/h to maximise remaining range.',
        'Switch off AC, heated seats, and rear defroster.',
        'Refuel with the correct fuel — check your fuel cap (unleaded or diesel).',
        'If you run dry, call roadside assistance — do not try to start the engine repeatedly.',
      ],
      isDIYFixable: true,
      youtubeQuery: 'what happens when you run out of petrol car tips',
    ),

    'images/BMW/oil light.png': WarningInfo(
      title: 'Low Oil Pressure',
      severity: 'critical',
      description:
          'Oil pressure has dropped to a dangerously low level. Engine '
          'components are not being lubricated. Continued driving can cause '
          'catastrophic engine damage — seized pistons, bent con-rods, '
          'or complete engine failure — within minutes.',
      driverActions: [
        'STOP THE CAR SAFELY AND IMMEDIATELY — do not keep driving even for 1 km.',
        'Turn the engine OFF.',
        'Do NOT restart until you have checked the oil level.',
        'Call roadside assistance if oil is empty.',
      ],
      diySteps: [
        'Wait 5 minutes for oil to drain back to the sump.',
        'Open the bonnet and locate the dipstick (usually yellow handle).',
        'Pull it out, wipe with a cloth, reinsert fully, pull out again.',
        'Oil should be between MIN and MAX marks.',
        'If low — add the correct engine oil (check owner manual for grade e.g. 5W-30).',
        'Add in small amounts (200ml), recheck after each addition.',
        'Do NOT overfill — oil above MAX is also damaging.',
        'If oil is fine but light stays on — the oil pressure sensor may be faulty. Seek professional help.',
      ],
      isDIYFixable: true,
      youtubeQuery: 'how to check engine oil level and top up BMW',
    ),

    'images/BMW/high heat.png': WarningInfo(
      title: 'Engine Overheating',
      severity: 'critical',
      description:
          'Engine temperature is dangerously high. Overheating can warp '
          'the cylinder head, blow the head gasket, crack the engine block, '
          'and cause permanent, irreparable engine damage. Every second '
          'of continued driving increases the damage.',
      driverActions: [
        'STOP THE ENGINE immediately and safely pull over.',
        'Do NOT open the bonnet or touch the radiator cap for at least 30 minutes.',
        'Turn the heater to maximum heat and full fan — this draws heat away from the engine.',
        'Do NOT pour cold water on the engine — thermal shock can crack the engine block.',
        'Call roadside assistance.',
      ],
      diySteps: [
        'After 30+ minutes of cooling, carefully open the bonnet.',
        'Check the coolant reservoir — it should be between MIN and MAX.',
        'If empty, inspect under the car for coolant puddles (green, orange, or pink liquid).',
        'If no puddles — slowly open the radiator cap with a thick cloth (cap may still be hot).',
        'Add 50/50 premixed coolant — never plain water alone.',
        'Check the radiator fan spins when engine is warm.',
        'Common causes: coolant leak, broken thermostat, head gasket failure, blocked radiator.',
        'Do not drive until the cause is identified and fixed.',
      ],
      isDIYFixable: false,
      youtubeQuery: 'car engine overheating what to do and how to fix',
    ),

    'images/BMW/tire presure waring.png': WarningInfo(
      title: 'Tyre Pressure Warning (TPMS)',
      severity: 'moderate',
      description:
          'One or more tyres is significantly underinflated. Low pressure '
          'causes poor handling, increased fuel consumption, uneven tyre wear, '
          'and greatly increases the risk of a tyre blowout at speed.',
      driverActions: [
        'Drive slowly to the nearest petrol station with an air pump.',
        'Avoid motorway speeds until tyres are correctly inflated.',
        'Visually inspect each tyre for obvious flat spots or damage.',
        'Check the spare tyre too.',
      ],
      diySteps: [
        'Find the correct pressure: check inside the driver door jamb sticker or owner manual.',
        'Typical pressure: 32–36 PSI (2.2–2.5 bar) — front and rear may differ.',
        'Use a digital tyre gauge to check all four tyres.',
        'Inflate to the correct pressure at a petrol station air pump.',
        'After inflating, drive a few km — the TPMS light should turn off.',
        'If one tyre keeps losing pressure, it has a slow puncture — visit a tyre shop.',
        'If all four were low, the TPMS sensor battery may have died — needs replacement.',
      ],
      isDIYFixable: true,
      youtubeQuery:
          'how to check and inflate tyre pressure TPMS warning light fix',
    ),

    'images/BMW/breake.png': WarningInfo(
      title: 'Brake System Warning',
      severity: 'critical',
      description:
          'A fault has been detected in the braking system. This could mean '
          'critically low brake fluid, worn brake pads down to the wear sensor, '
          'or a hydraulic system fault. Your ability to stop the vehicle '
          'may be seriously compromised.',
      driverActions: [
        'Test brake response gently — if soft or spongy, pull over immediately.',
        'If brakes feel normal, drive slowly and directly to a garage — no motorways.',
        'Increase following distance significantly.',
        'Avoid steep downhill sections.',
      ],
      diySteps: [
        'Check the brake fluid reservoir under the bonnet (marked with a brake symbol).',
        'Fluid should be between MIN and MAX lines.',
        'If low — top up with DOT 4 brake fluid (check cap for correct specification).',
        'Check handbrake is fully released — sometimes causes this light.',
        'Inspect brake pads through the wheel spoke — should have more than 2mm material.',
        'If pads are worn to metal — do NOT drive. Call for assistance.',
        'If fluid is full and pads are fine — a wheel sensor or brake circuit issue exists. Professional help required.',
      ],
      isDIYFixable: false,
      youtubeQuery: 'BMW brake warning light causes and fix',
    ),

    'images/BMW/ABS.png': WarningInfo(
      title: 'ABS Warning',
      severity: 'serious',
      description:
          'The Anti-lock Braking System has detected a fault. Your normal '
          'brakes still work, but ABS will not activate to prevent wheel '
          'lockup during emergency braking. This is especially dangerous '
          'on wet, icy, or loose surfaces.',
      driverActions: [
        'Normal braking still works — do not panic.',
        'Increase your following distance by 50%.',
        'Avoid emergency/hard braking situations.',
        'If both ABS and brake warning lights are on — stop driving immediately.',
        'Get the ABS system diagnosed at a garage.',
      ],
      diySteps: [
        'Try switching the car off, wait 30 seconds, and restart — may reset a temporary fault.',
        'Check all four wheel speed sensor connectors (visible near each brake disc).',
        'Clean sensors with a cloth if dirty — road debris is a common cause.',
        'Use an OBD2 scanner with ABS capability to read the specific fault code.',
        'Most common fix: replace the faulty wheel speed sensor (one per wheel).',
        'Cost: approx Rs. 3,000–8,000 per sensor at a mechanic.',
      ],
      isDIYFixable: false,
      youtubeQuery: 'ABS warning light fix wheel speed sensor replacement',
    ),

    'images/BMW/seatbelt.png': WarningInfo(
      title: 'Seatbelt Reminder',
      severity: 'info',
      description:
          'One or more occupants have not fastened their seatbelt. In a collision, '
          'an unfastened occupant is 30 times more likely to be ejected from the '
          'vehicle. Seatbelts are the single most effective safety device in any car.',
      driverActions: [
        'Ensure ALL passengers including rear seat occupants fasten their seatbelts.',
        'Do not drive until all seatbelts are fastened.',
        'Remind rear passengers — the sensor monitors all seats.',
      ],
      diySteps: [
        'Firmly click each seatbelt buckle into its receiver.',
        'Check rear passengers too.',
        'If the light stays on with all belts fastened — a buckle sensor is faulty.',
        'Try firmly clicking each buckle in and out 3–4 times.',
        'Identify the faulty buckle by process of elimination.',
        'Seatbelt buckle sensors can be replaced — cost: Rs. 1,500–4,000 at a mechanic.',
      ],
      isDIYFixable: true,
      youtubeQuery: 'seatbelt warning light stays on buckle sensor fix',
    ),

    'images/BMW/123.png': WarningInfo(
      title: 'Battery / Charging Warning',
      severity: 'serious',
      description:
          'The battery is not being charged by the alternator. The car is '
          'running solely on battery power. Once the battery drains, '
          'the engine will stop — including power steering and brakes. '
          'This is usually caused by a failed alternator or broken drive belt.',
      driverActions: [
        'Turn off ALL non-essential electronics — AC, radio, heated seats, rear defroster.',
        'Drive directly to a garage or home — do not turn the engine off.',
        'Estimate 20–40 minutes of running time remaining.',
        'Hazard lights consume power — only use if essential.',
      ],
      diySteps: [
        'Check the drive belt (serpentine belt) under the bonnet — should be intact and taut.',
        'If belt is broken — do NOT drive. Call for roadside assistance.',
        'Check battery terminal connections — must be tight and corrosion-free.',
        'Clean corrosion with baking soda + water and a wire brush.',
        'Have the battery and alternator tested (many auto parts shops do this free).',
        'Battery older than 3–4 years: likely needs replacement.',
        'Alternator failure: requires professional replacement.',
      ],
      isDIYFixable: false,
      youtubeQuery: 'BMW battery charging warning light alternator failure fix',
    ),

    'images/BMW/airbag waring.png': WarningInfo(
      title: 'Airbag / SRS Warning',
      severity: 'serious',
      description:
          'The Supplemental Restraint System has a fault. Airbags may not '
          'deploy in a collision — or could deploy unexpectedly. '
          'This is a safety-critical issue that must not be ignored. '
          'Common causes: faulty crash sensor, clock spring, or seat occupancy sensor.',
      driverActions: [
        'Do not place bags, boxes or heavy items under the front seats — wiring harnesses are there.',
        'Do not attempt to service the airbag system yourself — risk of accidental deployment.',
        'Have the system professionally diagnosed as soon as possible.',
      ],
      diySteps: [
        'Check all seat connectors under each seat — ensure they are firmly plugged in.',
        'Check the connectors under the steering column (clock spring area).',
        'Use an OBD2 scanner with SRS airbag capability to read the fault code.',
        'Common faults: B0001 (driver airbag), clock spring, seat occupancy sensor.',
        'Airbag clock springs can be DIY replaced by experienced mechanics — involves removing the steering wheel.',
        'All other airbag repairs: professional workshop only.',
      ],
      isDIYFixable: false,
      youtubeQuery: 'SRS airbag warning light causes diagnosis and fix',
    ),

    'images/BMW/e brake.png': WarningInfo(
      title: 'Electronic Parking Brake / Brake Hold',
      severity: 'moderate',
      description:
          'The electronic parking brake (EPB) is engaged or has a system fault. '
          'Driving with the parking brake engaged causes rapid brake overheating, '
          'glazed brake pads, and damage to the rear brake discs.',
      driverActions: [
        'Ensure the parking brake is fully released before driving.',
        'If the EPB shows a fault — restart the car to attempt a reset.',
        'If light stays on while driving — pull over and check.',
      ],
      diySteps: [
        'Press the EPB button/switch firmly to release.',
        'For BMW iDrive: check for any related error messages on the screen.',
        'Switch the car off, wait 30 seconds, restart.',
        'If fault persists: an EPB actuator motor at one of the rear calipers may be faulty.',
        'EPB actuator replacement: professional repair, cost Rs. 8,000–20,000.',
      ],
      isDIYFixable: false,
      youtubeQuery: 'BMW electronic parking brake warning fault fix EPB',
    ),

    'images/BMW/fog lights.png': WarningInfo(
      title: 'Fog Lights Active',
      severity: 'info',
      description:
          'Front or rear fog lights are switched on. Fog lights produce a '
          'wide, flat beam to cut through fog. Using them in clear conditions '
          'dazzles other drivers and is illegal in many countries.',
      driverActions: [
        'Only use fog lights when visibility is below 100 metres.',
        'Turn them off in clear conditions.',
        'Remember: rear fog lights are especially blinding to following traffic.',
      ],
      diySteps: [
        'Locate the fog light switch on the light stalk or dashboard.',
        'Push or rotate to the fog light symbol to toggle on/off.',
        'If fog lights stay on when switched off — the switch or relay is faulty.',
      ],
      isDIYFixable: true,
      youtubeQuery: 'when to use fog lights driving guide rules',
    ),

    'images/BMW/glow.png': WarningInfo(
      title: 'Diesel Glow Plug Pre-heating',
      severity: 'info',
      description:
          'Diesel glow plugs are heating the combustion chambers to aid cold '
          'starting. This is completely normal, especially in cold weather. '
          'Starting the engine before this light turns off can cause hard '
          'starting and carbon buildup.',
      driverActions: [
        'Wait for this light to turn off completely before turning the ignition key to start.',
        'In very cold weather, this may take 5–10 seconds.',
        'Do not crank the engine while this light is on.',
      ],
      diySteps: [
        'If the light stays on permanently (not during warm-up) — one or more glow plugs have failed.',
        'Signs of failed glow plugs: white smoke on cold start, hard starting, rough idle.',
        'Use OBD2 scanner to confirm and identify which cylinder.',
        'Glow plug replacement: moderate DIY — requires a torque wrench and glow plug socket.',
        '4 cylinder engine: replace all glow plugs at once when one fails.',
        'Cost: Rs. 500–1,500 per plug. Labour at mechanic: Rs. 3,000–6,000.',
      ],
      isDIYFixable: true,
      youtubeQuery: 'diesel glow plug replacement how to DIY',
    ),

    'images/BMW/TRC.png': WarningInfo(
      title: 'Traction / Stability Control Warning',
      severity: 'moderate',
      description:
          'Traction control (TCS) or Dynamic Stability Control (DSC) is either '
          'actively intervening on a slippery surface (normal — light flashes) '
          'or has a system fault (light stays on solid). '
          'Without these systems, the car is less stable in corners and on slippery roads.',
      driverActions: [
        'Flashing light while driving on slippery road: this is NORMAL — slow down.',
        'Solid light that stays on: traction/stability control is disabled.',
        'Drive smoothly — gentle steering, acceleration, and braking.',
        'Get the system diagnosed soon.',
      ],
      diySteps: [
        'Press the DSC/TCS button to switch off and back on.',
        'Restart the car — may reset a temporary fault.',
        'Check all four wheel speed sensors for dirt or damage.',
        'Use OBD2 scanner to read fault codes.',
        'Faulty wheel speed sensor is the most common cause.',
        'Also check steering angle sensor (requires calibration after replacement).',
      ],
      isDIYFixable: false,
      youtubeQuery: 'BMW DSC traction control warning light fix causes',
    ),

    'images/BMW/warning.png': WarningInfo(
      title: 'General Vehicle Warning',
      severity: 'moderate',
      description:
          'A non-specific warning has been detected. BMW iDrive will usually '
          'display an accompanying message explaining the exact issue. '
          'Check all fluid levels and read any displayed messages.',
      driverActions: [
        'Check the iDrive display for any related message or fault description.',
        'Check engine oil, coolant, brake fluid, and washer fluid levels.',
        'Use an OBD2 scanner to read any stored fault codes.',
      ],
      diySteps: [
        'Read the iDrive message carefully — it usually tells you exactly what is wrong.',
        'Check all fluids under the bonnet.',
        'Connect an OBD2 reader for detailed fault codes.',
        'Research the specific code for your BMW model on forums.',
        'bimmerpost.com and bimmerfest.com have excellent BMW-specific resources.',
      ],
      isDIYFixable: true,
      youtubeQuery: 'BMW warning light general fault diagnosis OBD2',
    ),

    'images/BMW/window heater.png': WarningInfo(
      title: 'Rear Window Defroster / Heater',
      severity: 'info',
      description:
          'The rear window electric heater is active, clearing frost, '
          'condensation, or ice. This is completely normal. '
          'It draws power from the battery — turn it off once the window is clear.',
      driverActions: [
        'No action needed — this is normal operation.',
        'Turn off once the window is fully clear to conserve battery.',
      ],
      diySteps: [
        'If the rear window does not clear — the heating element grid may be broken.',
        'Look closely at the rear window for breaks in the thin printed lines.',
        'Broken lines can be repaired with a rear defroster repair kit (Rs. 500–1,500).',
        'Clean the window with a damp cloth — dirt reduces effectiveness.',
        'If the button does not activate the heater — check the fuse first.',
      ],
      isDIYFixable: true,
      youtubeQuery: 'rear window defroster not working repair kit how to fix',
    ),

    // ══════════════════════════════════════════════════════════════
    // TOYOTA / UNIVERSAL INDICATORS
    // (Used for Toyota, Nissan, Honda, Suzuki, Mazda, Kia, Hyundai)
    // ══════════════════════════════════════════════════════════════
    'images/Toyota/ENGINE CHECK LIGHT.png': WarningInfo(
      title: 'Check Engine (MIL)',
      severity: 'serious',
      description:
          'The engine control module has detected a fault in the engine or '
          'emissions system. Steady light: get it checked soon. '
          'Flashing light: serious misfire occurring — reduce speed immediately. '
          'Common causes: loose fuel cap, oxygen sensor, catalytic converter, spark plugs.',
      driverActions: [
        'If FLASHING — reduce speed, avoid high RPM, pull over when safe.',
        'If STEADY — check the fuel cap first, then get it scanned.',
        'Do not ignore — unresolved faults can cause further damage.',
        'Avoid towing or heavy loads until resolved.',
      ],
      diySteps: [
        'Tighten the fuel cap until it clicks — most common cause.',
        'Drive 3–5 km and see if the light clears on its own.',
        'Plug in an OBD2 scanner to the diagnostic port under the dashboard.',
        'Write down the fault code (e.g. P0420, P0171, P0300).',
        'Search: "[your car brand] [fault code] fix" on YouTube.',
        'Common DIY repairs: clean MAF sensor, replace O2 sensor, replace spark plugs.',
      ],
      isDIYFixable: true,
      youtubeQuery: 'check engine light causes and how to fix any car',
    ),

    'images/Toyota/LOW FUEL.png': WarningInfo(
      title: 'Low Fuel Warning',
      severity: 'moderate',
      description:
          'Fuel is critically low. Most vehicles have approximately 10–15 km '
          'of remaining range when this light comes on. Running out of fuel '
          'can damage the fuel pump (which relies on fuel for cooling) '
          'and leave debris from the tank bottom in the fuel system.',
      driverActions: [
        'Find the nearest petrol station and refuel immediately.',
        'Reduce your speed to extend the remaining range.',
        'Turn off air conditioning to conserve fuel.',
      ],
      diySteps: [
        'Drive at a steady moderate speed (avoid stop-start traffic if possible).',
        'Switch off AC, heated seats, and other high-draw accessories.',
        'Check your fuel cap for the correct fuel type (petrol/diesel/95/92 octane).',
        'If you run dry: do not repeatedly crank the engine. Call for fuel delivery.',
        'After refuelling following an empty tank, prime the system by cycling the ignition 3 times before starting.',
      ],
      isDIYFixable: true,
      youtubeQuery: 'what to do when low fuel warning light comes on',
    ),

    'images/Toyota/WATER HEAT.png': WarningInfo(
      title: 'Engine Overheating',
      severity: 'critical',
      description:
          'Coolant temperature is dangerously high. The engine is overheating. '
          'This can cause head gasket failure, warped cylinder head, cracked '
          'engine block — all extremely expensive repairs. '
          'Every second of continued driving worsens the damage.',
      driverActions: [
        'PULL OVER SAFELY AND TURN ENGINE OFF — do not drive another kilometre.',
        'Do NOT open the bonnet for at least 30 minutes.',
        'Do NOT remove the radiator or coolant cap — pressurised hot coolant can cause severe burns.',
        'Turn heater to maximum to help draw engine heat away (if still moving).',
        'Call roadside assistance.',
      ],
      diySteps: [
        'After 30+ minutes: open bonnet and check the coolant reservoir level.',
        'If empty: look under the car for coolant puddles (usually green, orange, or blue/purple liquid).',
        'If no leaks: carefully (with thick cloth) open the coolant cap and add 50/50 premixed coolant.',
        'Check the cooling fan — it should spin when the engine warms up.',
        'Common causes: coolant leak (hose, radiator), faulty thermostat, broken water pump, blown head gasket.',
        'Head gasket symptoms: white exhaust smoke, oil in coolant (milky/frothy oil cap), bubbles in coolant.',
        'Do not drive until a mechanic has inspected the cooling system.',
      ],
      isDIYFixable: false,
      youtubeQuery: 'engine overheating causes and what to do car',
    ),

    'images/Toyota/BATTERY CHECK.png': WarningInfo(
      title: 'Battery / Charging System Warning',
      severity: 'serious',
      description:
          'The alternator is not charging the battery. The car is running on '
          'battery reserve power only. When the battery is exhausted, '
          'the engine will stop — losing power steering and brake assistance. '
          'You may have 20–40 minutes of driving time remaining.',
      driverActions: [
        'Switch off ALL non-essential electrics: AC, radio, heated seats, phone chargers.',
        'Drive directly to the nearest garage or safe location.',
        'Do NOT switch the engine off — it may not restart.',
        'Dim the interior lights if possible.',
      ],
      diySteps: [
        'Check battery terminals: corrosion (white/blue powder) restricts charging.',
        'Clean terminals with baking soda dissolved in water + a wire brush.',
        'Check the drive belt is intact and correctly tensioned.',
        'Have battery voltage tested: should read 12.6V at rest, 13.8–14.4V while running.',
        'Below 13.8V while running = alternator is failing.',
        'Batteries over 3–4 years old should be replaced proactively.',
        'Alternator replacement: professional repair, cost Rs. 15,000–35,000.',
      ],
      isDIYFixable: false,
      youtubeQuery: 'battery warning light car alternator failure what to do',
    ),

    'images/Toyota/HAND BREAK.png': WarningInfo(
      title: 'Parking Brake Warning',
      severity: 'moderate',
      description:
          'The handbrake (parking brake) is engaged or the brake fluid level '
          'is dangerously low. Driving with the handbrake on causes the rear '
          'brakes to overheat rapidly, glazing the pads and warping the discs. '
          'Low fluid means a brake system leak — serious safety risk.',
      driverActions: [
        'Release the handbrake completely before driving.',
        'If light stays on after releasing — check brake fluid level immediately.',
        'If brake fluid is very low — do NOT drive. Call for assistance.',
      ],
      diySteps: [
        'Engage and fully release the handbrake lever.',
        'For foot-operated park brake: press and release firmly.',
        'Open bonnet and check brake fluid reservoir — should be between MIN and MAX.',
        'If low: top up with DOT 4 brake fluid.',
        'Check for fluid leaks: look under the car for wet spots or fluid trails near wheels.',
        'If fluid is fine and handbrake is released but light stays on: handbrake switch is faulty.',
        'Handbrake switch replacement: usually DIY-accessible, cost Rs. 500–1,500.',
      ],
      isDIYFixable: true,
      youtubeQuery:
          'handbrake parking brake warning light stays on fix brake fluid',
    ),

    'images/Toyota/seat bealts.png': WarningInfo(
      title: 'Seatbelt Reminder',
      severity: 'info',
      description:
          'A seatbelt in the vehicle is not fastened. In a crash at 60 km/h, '
          'an unrestrained occupant continues moving at 60 km/h and can be '
          'killed or ejected. Seatbelts reduce fatality risk by 45% for '
          'front seat occupants and 60% for rear seat occupants.',
      driverActions: [
        'Ensure ALL occupants — including rear passengers — have their seatbelts fastened.',
        'Do not move the vehicle until all belts are secured.',
      ],
      diySteps: [
        'Check ALL seats including rear passengers.',
        'Firmly click each seatbelt until you hear a clear click.',
        'If light stays on with all belts fastened — a buckle sensor is defective.',
        'Test each buckle by inserting and removing the tongue multiple times.',
        'The defective one may feel loose or not click solidly.',
        'Replacement buckle sensors: Rs. 1,500–4,000 at a mechanic.',
      ],
      isDIYFixable: true,
      youtubeQuery: 'seatbelt warning light always on fix buckle sensor',
    ),

    'images/Toyota/ABS.png': WarningInfo(
      title: 'ABS (Anti-lock Braking) Warning',
      severity: 'serious',
      description:
          'The Anti-lock Braking System has a fault and is disabled. '
          'Your regular brakes still work. However, during emergency braking, '
          'the wheels can lock up, causing the car to skid and lose steering '
          'control — especially dangerous in wet weather.',
      driverActions: [
        'Regular braking still works — do not panic.',
        'Increase following distance by at least 50%.',
        'Apply brakes smoothly and progressively — avoid stamping hard.',
        'Both ABS AND brake lights on together: stop driving immediately — serious brake fault.',
        'Have ABS diagnosed at a garage soon.',
      ],
      diySteps: [
        'Switch off the car, wait 30 seconds, and restart — may clear temporary faults.',
        'Inspect all four wheel speed sensors (located near each brake disc/hub).',
        'Clean sensors with a dry cloth — mud and debris are common culprits.',
        'Check sensor wiring for cuts or corrosion.',
        'Plug in an OBD2 scanner with ABS support to read the exact fault code.',
        'Typical fix: replace the faulty wheel speed sensor. Cost: Rs. 2,000–8,000 per sensor.',
      ],
      isDIYFixable: false,
      youtubeQuery:
          'ABS warning light fix how to replace wheel speed sensor car',
    ),

    'images/Toyota/DOORS OPEND.png': WarningInfo(
      title: 'Door / Boot Ajar Warning',
      severity: 'info',
      description:
          'One or more doors, the boot, or the bonnet is not fully latched. '
          'A door that opens at speed can cause a serious accident, '
          'and an open boot reduces visibility and can shed items onto the road.',
      driverActions: [
        'Pull over safely and physically check all doors — push each one firmly.',
        'Check the boot/tailgate and bonnet.',
        'Do not drive at speed with a door ajar.',
      ],
      diySteps: [
        'Check that no items are caught in door seals (bags, clothing, seatbelts).',
        'Push each door firmly from the outside until it clicks fully shut.',
        'If the light stays on with all doors shut — a door ajar microswitch is faulty.',
        'The switch is inside the door latch mechanism — test by opening and closing quickly.',
        'Spray the latch with silicone lubricant — sometimes a sticky latch causes this.',
        'Door ajar switch replacement: Rs. 500–2,000 at a mechanic.',
      ],
      isDIYFixable: true,
      youtubeQuery: 'door ajar warning light stays on fix door latch switch',
    ),

    'images/Toyota/HAZARD.png': WarningInfo(
      title: 'Hazard Warning Lights',
      severity: 'info',
      description:
          'All four indicators are flashing simultaneously. Hazard lights '
          'signal to other drivers that your vehicle is stationary and poses '
          'a hazard. Using them while driving (except in emergencies) '
          'confuses other drivers and is illegal in many countries.',
      driverActions: [
        'Use hazard lights only when your vehicle is stationary and poses a risk to others.',
        'Some countries allow brief use during emergency braking on motorways.',
        'Turn them off once you are safely out of traffic or the hazard is resolved.',
      ],
      diySteps: [
        'Press the red hazard triangle button (usually on the dashboard centre) to toggle.',
        'If hazard lights flash when not activated — the hazard switch relay is faulty.',
        'Locate the hazard relay in the fuse box (check owner manual for position).',
        'Replace the relay — usually costs Rs. 200–500.',
      ],
      isDIYFixable: true,
      youtubeQuery: 'when and how to use hazard lights correctly driving rules',
    ),

    'images/Toyota/HEAD BEAM.png': WarningInfo(
      title: 'High Beam (Full Beam) Active',
      severity: 'info',
      description:
          'High beam headlights are on. These greatly improve your forward '
          'visibility on dark unlit roads but blind oncoming drivers and '
          'following vehicles. Failure to dip headlights is illegal and '
          'dangerous.',
      driverActions: [
        'Switch to low beam when you see oncoming headlights.',
        'Switch to low beam when following another vehicle within 200m.',
        'Use high beams only on completely unlit roads with no other vehicles.',
      ],
      diySteps: [
        'Pull the headlight stalk towards you briefly to flash/toggle high beam.',
        'Push the stalk forward to select high beam on most cars.',
        'If high beam stays on and cannot be turned off — the stalk switch or relay is faulty.',
        'Check the headlight stalk switch — replacement: Rs. 2,000–5,000.',
      ],
      isDIYFixable: true,
      youtubeQuery: 'how to use high beam headlights correctly when to dip',
    ),

    'images/Toyota/LOW BEAM.png': WarningInfo(
      title: 'Headlights (Low Beam) Active',
      severity: 'info',
      description:
          'Low beam headlights are switched on. This is correct and normal '
          'for night driving, tunnels, and poor visibility conditions. '
          'Ensure both headlights are working correctly.',
      driverActions: [
        'No action needed in normal operation.',
        'Turn on headlights at dusk, in rain, and whenever visibility is reduced.',
        'Check both headlight bulbs are working by walking around the car.',
      ],
      diySteps: [
        'If one headlight is out: replace the bulb promptly.',
        'Halogen bulbs (H4, H7, H11): accessible from the engine bay — unplug, unclip, replace.',
        'Cost: Rs. 200–800 per halogen bulb.',
        'LED/HID (xenon) headlights: require professional replacement.',
        'If headlights flicker: check the headlight relay and earth connections.',
        'Yellowed/foggy headlight lenses: use a headlight restoration kit to improve brightness.',
      ],
      isDIYFixable: true,
      youtubeQuery: 'how to replace headlight bulb car step by step DIY',
    ),

    'images/Toyota/WINDSCREEN WASHER LIQUID LOW.png': WarningInfo(
      title: 'Windscreen Washer Fluid Low',
      severity: 'info',
      description:
          'The windscreen washer fluid reservoir is empty or nearly empty. '
          'While not a mechanical emergency, a dirty windscreen in bright '
          'sunlight or oncoming headlights can blind the driver completely '
          'and cause accidents.',
      driverActions: [
        'Refill at the next convenient opportunity.',
        'Do not use plain water in cold weather — it freezes in the pipes and can crack them.',
        'Avoid using the washers when empty — the pump runs dry and can burn out.',
      ],
      diySteps: [
        'Open the bonnet and locate the washer reservoir (marked with a windscreen spray symbol — usually blue cap).',
        'Fill with dedicated windscreen washer fluid — not engine coolant.',
        'In summer: dilute 1:10 with water. In winter: use undiluted screen wash.',
        'In an emergency: diluted dishwashing liquid works temporarily.',
        'If washer jets are blocked: use a pin to gently clear the nozzle holes.',
        'Adjust jet direction with a pin if they spray too high or low.',
        'If pump does not operate after refilling: check the washer pump fuse.',
      ],
      isDIYFixable: true,
      youtubeQuery:
          'how to refill windscreen washer fluid and fix blocked washer jets',
    ),
  };

  // ── Get severity style ─────────────────────────────────────────────────────
  static Map<String, dynamic> getSeverityStyle(String severity) {
    switch (severity) {
      case 'critical':
        return {
          'color': const Color(0xFFCF4D6F),
          'label': 'CRITICAL — Stop Immediately',
          'icon': '🚨',
        };
      case 'serious':
        return {
          'color': const Color(0xFFE07B39),
          'label': 'SERIOUS — Act Soon',
          'icon': '⚠️',
        };
      case 'moderate':
        return {
          'color': const Color(0xFFC9A84C),
          'label': 'MODERATE — Monitor Closely',
          'icon': '🔔',
        };
      default:
        return {
          'color': const Color(0xFF4CAF7D),
          'label': 'INFORMATIONAL',
          'icon': 'ℹ️',
        };
    }
  }
}
