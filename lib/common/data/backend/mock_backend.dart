import 'dart:math';

import 'package:client/common/data/backend/backend.dart';
import 'package:flutter/foundation.dart';
import 'package:client/common/data/models/job_order_item.dart';
import 'package:client/common/data/models/job_order_model.dart';
import 'package:client/common/data/models/merchant_category.dart';
import 'package:client/common/data/models/merchant_light.dart';
import 'package:client/common/data/models/merchant_model.dart';
import 'package:client/common/data/models/merchant_service.dart';
import 'package:client/common/data/models/merchant_service_option.dart';
import 'package:client/common/data/models/service_coverage_geo.dart';
import 'package:client/common/data/models/user_address_model.dart';
import 'package:client/common/data/models/user_session.dart';
import 'package:client/modules/homepage/data/models/search_service_result.dart';
import 'package:client/modules/job_order/data/enums/job_order_status.dart';
import 'package:client/modules/job_order/data/models/jo_details.dart';
import 'package:client/modules/job_order/data/models/merchant_user.dart';
import 'package:client/modules/registration/data/models/registration_form_model.dart';
import 'package:client/modules/store_items/data/models/store_option_items.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// In-memory mocked backend to make the app runnable without any API server.
class MockBackend implements Backend {
  MockBackend() {
    assert(!kReleaseMode, 'MockBackend must not be used in release builds');
  }

  final _rng = Random(42);

  final List<MerchantLight> _merchants = [
    const MerchantLight(
      merchantID: 'servana',
      merchantName: 'Servana',
      city: 'Makati',
      latitude: 14.5547,
      longitude: 121.0244,
      rating: 0,
      listImage: null,
      discounts: [10, 15],
      merchantStatus: 1,
      merchantStatusToString: 'Active',
    ),
  ];

  final Map<String, MerchantModel> _merchantDetails = {
    'servana': MerchantModel(
      merchantID: 'servana',
      bankID: 1,
      merchantName: 'Servana',
      businessOwnerName: 'Servana',
      merchantStatus: 1,
      contactNumber: '+63 900 000 0001',
      emailAddress: 'sparkle@example.com',
      officeAddress: 'Makati, Metro Manila',
      officeContactNumber: '+63 900 000 0001',
      currentCredit: 1000,
      bankAccountNumber: '000-000-000',
      bankAccountName: 'Servana',
      rating: 0,
      merchantFee: 10,
      businessType: 1,
      representativeIDType: 1,
      representativeIDFrontDocumentFilename: 'id_front.png',
      representativeIDBackDocumentFilename: 'id_back.png',
      tin: '000-000-000',
      distanceCoverage: 10,
      freeDistanceTransportationFee: 3,
      createdDate: DateTime(2024, 1, 1),
    ),
  };

  final Map<String, List<MerchantServiceModel>> _servicesByMerchant = {
    'servana': [
      // ═══════════════════════════════════════════════════════════════════════
      // BEAUTY & WELLNESS (Category ID: 1)
      // ═══════════════════════════════════════════════════════════════════════

      // ─────────────────────────────────────────────────────────────────────
      // DRIP (Subcategory ID: 10)
      // ─────────────────────────────────────────────────────────────────────
      MerchantServiceModel(
        merchantServiceID: 101,
        merchantCategoryID: 1,
        merchantCategoryName: 'Beauty & Wellness',
        merchantSubcategoryID: 10,
        merchantSubcategoryName: 'Drip',
        merchantServiceName: 'Gluta Drip',
        merchantServiceDescription: 'Tationil (600), Vitamin C, Vitamin B.',
        amount: 990,
        ordinal: 0,
        merchantServiceBillingType: 1,
        recommendation: 'per session',
        baseFair: 0,
        selectionOptions: [],
      ),
      MerchantServiceModel(
        merchantServiceID: 102,
        merchantCategoryID: 1,
        merchantCategoryName: 'Beauty & Wellness',
        merchantSubcategoryID: 10,
        merchantSubcategoryName: 'Drip',
        merchantServiceName: 'Swiss Drip',
        merchantServiceDescription:
            'Gluta (1200), C, B, Collagen, Hya, EGP, Lipoic Acid, Kojic, Peptide, Placenta, Coq10.',
        amount: 1500,
        ordinal: 1,
        merchantServiceBillingType: 1,
        recommendation: 'per session',
        baseFair: 0,
        selectionOptions: [],
      ),
      MerchantServiceModel(
        merchantServiceID: 103,
        merchantCategoryID: 1,
        merchantCategoryName: 'Beauty & Wellness',
        merchantSubcategoryID: 10,
        merchantSubcategoryName: 'Drip',
        merchantServiceName: 'Japanese Drip',
        merchantServiceDescription:
            'Gluta (5000mg), C, B, Thioctic, Collagen, Embryonic Stem Cell, Kojic, Amino Acid, Human Placenta.',
        amount: 2500,
        ordinal: 2,
        merchantServiceBillingType: 1,
        recommendation: 'per session',
        baseFair: 0,
        selectionOptions: [],
      ),
      MerchantServiceModel(
        merchantServiceID: 104,
        merchantCategoryID: 1,
        merchantCategoryName: 'Beauty & Wellness',
        merchantSubcategoryID: 10,
        merchantSubcategoryName: 'Drip',
        merchantServiceName: "Emperor's Drip",
        merchantServiceDescription:
            'Gluta (300k mg), C, B, Collagen, Celergen Stem Cell, Vegetable Placenta, Coq10, N-ALA+.',
        amount: 3500,
        ordinal: 3,
        merchantServiceBillingType: 1,
        recommendation: 'per session',
        baseFair: 0,
        selectionOptions: [],
      ),
      MerchantServiceModel(
        merchantServiceID: 105,
        merchantCategoryID: 1,
        merchantCategoryName: 'Beauty & Wellness',
        merchantSubcategoryID: 10,
        merchantSubcategoryName: 'Drip',
        merchantServiceName: "Governor's Drip",
        merchantServiceDescription:
            'The ultimate drip treatment, a powerful combination of all drip formulas in one.',
        amount: 4500,
        ordinal: 4,
        merchantServiceBillingType: 1,
        recommendation: 'per session',
        baseFair: 0,
        selectionOptions: [],
      ),

      // ─────────────────────────────────────────────────────────────────────
      // FACIAL (Subcategory ID: 20)
      // ─────────────────────────────────────────────────────────────────────
      MerchantServiceModel(
        merchantServiceID: 201,
        merchantCategoryID: 1,
        merchantCategoryName: 'Beauty & Wellness',
        merchantSubcategoryID: 20,
        merchantSubcategoryName: 'Facial',
        merchantServiceName: 'Deep Cleansing Facial',
        merchantServiceDescription:
            'Classic offering that attempts to nourish and regenerate your facial skin, making it appear healthier and younger.',
        amount: 1000,
        ordinal: 0,
        merchantServiceBillingType: 1,
        recommendation: 'per session',
        baseFair: 0,
        selectionOptions: [],
      ),
      MerchantServiceModel(
        merchantServiceID: 202,
        merchantCategoryID: 1,
        merchantCategoryName: 'Beauty & Wellness',
        merchantSubcategoryID: 20,
        merchantSubcategoryName: 'Facial',
        merchantServiceName: 'Collagen Facial',
        merchantServiceDescription:
            'Aims to put a stop to the aging process by externally applying collagen to the skin so that it can penetrate the dermis directly.',
        amount: 1500,
        ordinal: 1,
        merchantServiceBillingType: 1,
        recommendation: 'per session',
        baseFair: 0,
        selectionOptions: [],
      ),
      MerchantServiceModel(
        merchantServiceID: 203,
        merchantCategoryID: 1,
        merchantCategoryName: 'Beauty & Wellness',
        merchantSubcategoryID: 20,
        merchantSubcategoryName: 'Facial',
        merchantServiceName: 'Whitening Facial',
        merchantServiceDescription:
            "Softly lightens freckles, dark spots, hyperpigmentation while retaining the skin's natural color.",
        amount: 1500,
        ordinal: 2,
        merchantServiceBillingType: 1,
        recommendation: 'per session',
        baseFair: 0,
        selectionOptions: [],
      ),
      MerchantServiceModel(
        merchantServiceID: 204,
        merchantCategoryID: 1,
        merchantCategoryName: 'Beauty & Wellness',
        merchantSubcategoryID: 20,
        merchantSubcategoryName: 'Facial',
        merchantServiceName: 'Pimple Facial',
        merchantServiceDescription:
            'Suitable for individuals of all ages who have acne-prone skin.',
        amount: 1500,
        ordinal: 3,
        merchantServiceBillingType: 1,
        recommendation: 'per session',
        baseFair: 0,
        selectionOptions: [],
      ),
      MerchantServiceModel(
        merchantServiceID: 205,
        merchantCategoryID: 1,
        merchantCategoryName: 'Beauty & Wellness',
        merchantSubcategoryID: 20,
        merchantSubcategoryName: 'Facial',
        merchantServiceName: 'Signature Facial',
        merchantServiceDescription:
            'Signature facial that offers a great treatment specialized for your current skin condition.',
        amount: 2000,
        ordinal: 4,
        merchantServiceBillingType: 1,
        recommendation: 'per session',
        baseFair: 0,
        selectionOptions: [],
      ),
      MerchantServiceModel(
        merchantServiceID: 206,
        merchantCategoryID: 1,
        merchantCategoryName: 'Beauty & Wellness',
        merchantSubcategoryID: 20,
        merchantSubcategoryName: 'Facial',
        merchantServiceName: 'Hydra Facial',
        merchantServiceDescription:
            'Suitable for all skin types and works to improve radiance, hydration, plumping, and brightening that is supple to the touch.',
        amount: 3500,
        ordinal: 5,
        merchantServiceBillingType: 1,
        recommendation: 'per session',
        baseFair: 0,
        selectionOptions: [],
      ),
      MerchantServiceModel(
        merchantServiceID: 207,
        merchantCategoryID: 1,
        merchantCategoryName: 'Beauty & Wellness',
        merchantSubcategoryID: 20,
        merchantSubcategoryName: 'Facial',
        merchantServiceName: 'Celebrity Hydra Facial',
        merchantServiceDescription:
            'Combination of Signature and Hydra Facial. Bespoke skincare treatment that will reveal the radiant glow and immaculate complexion of the stars on the red carpet.',
        amount: 5000,
        ordinal: 6,
        merchantServiceBillingType: 1,
        recommendation: 'per session',
        baseFair: 0,
        selectionOptions: [],
      ),
      MerchantServiceModel(
        merchantServiceID: 208,
        merchantCategoryID: 1,
        merchantCategoryName: 'Beauty & Wellness',
        merchantSubcategoryID: 20,
        merchantSubcategoryName: 'Facial',
        merchantServiceName: 'Vampire Facial',
        merchantServiceDescription:
            'Platelet-rich plasma (PRP) treatment with signature facial. Reduces wrinkles, plumps up drooping skin, removes deep creases, lessens acne scars, and brightens the complexion.',
        amount: 6000,
        ordinal: 7,
        merchantServiceBillingType: 1,
        recommendation: 'per session',
        baseFair: 0,
        selectionOptions: [],
      ),

      // ─────────────────────────────────────────────────────────────────────
      // MASSAGE & WELLNESS (Subcategory ID: 30)
      // ─────────────────────────────────────────────────────────────────────
      MerchantServiceModel(
        merchantServiceID: 301,
        merchantCategoryID: 1,
        merchantCategoryName: 'Beauty & Wellness',
        merchantSubcategoryID: 30,
        merchantSubcategoryName: 'Massage & Wellness',
        merchantServiceName: 'Body Massage',
        merchantServiceDescription:
            'Soothing therapy that uses calming strokes and gentle pressure to relax the muscles, improve blood flow, and restore balance to the body.',
        amount: 400,
        ordinal: 0,
        merchantServiceBillingType: 1,
        recommendation: 'per hour',
        baseFair: 0,
        selectionOptions: [],
      ),
      MerchantServiceModel(
        merchantServiceID: 302,
        merchantCategoryID: 1,
        merchantCategoryName: 'Beauty & Wellness',
        merchantSubcategoryID: 30,
        merchantSubcategoryName: 'Massage & Wellness',
        merchantServiceName: 'Foot Massage',
        merchantServiceDescription:
            'Therapeutic treatment that applies pressure to specific points on the feet to help stimulate energy flow throughout the body.',
        amount: 400,
        ordinal: 1,
        merchantServiceBillingType: 1,
        recommendation: 'per hour',
        baseFair: 0,
        selectionOptions: [],
      ),
      MerchantServiceModel(
        merchantServiceID: 303,
        merchantCategoryID: 1,
        merchantCategoryName: 'Beauty & Wellness',
        merchantSubcategoryID: 30,
        merchantSubcategoryName: 'Massage & Wellness',
        merchantServiceName: 'Face Massage',
        merchantServiceDescription:
            'Rejuvenating treatment that gently lifts, tones, and relaxes the face, leaving your skin glowing and refreshed.',
        amount: 400,
        ordinal: 2,
        merchantServiceBillingType: 1,
        recommendation: 'per hour',
        baseFair: 0,
        selectionOptions: [],
      ),
      MerchantServiceModel(
        merchantServiceID: 304,
        merchantCategoryID: 1,
        merchantCategoryName: 'Beauty & Wellness',
        merchantSubcategoryID: 30,
        merchantSubcategoryName: 'Massage & Wellness',
        merchantServiceName: 'Head Back & Shoulder Massage',
        merchantServiceDescription:
            'Relaxing therapy that helps reduce stress, relieve body aches, and relax tight muscles in the upper body.',
        amount: 400,
        ordinal: 3,
        merchantServiceBillingType: 1,
        recommendation: 'per hour',
        baseFair: 0,
        selectionOptions: [],
      ),
      MerchantServiceModel(
        merchantServiceID: 305,
        merchantCategoryID: 1,
        merchantCategoryName: 'Beauty & Wellness',
        merchantSubcategoryID: 30,
        merchantSubcategoryName: 'Massage & Wellness',
        merchantServiceName: 'Ventosa',
        merchantServiceDescription:
            'Traditional therapeutic treatment that uses suction cups on the skin to stimulate blood circulation, relieve muscle tension, and promote natural healing.',
        amount: 1000,
        ordinal: 4,
        merchantServiceBillingType: 1,
        recommendation: 'per hour',
        baseFair: 0,
        selectionOptions: [],
      ),
      MerchantServiceModel(
        merchantServiceID: 306,
        merchantCategoryID: 1,
        merchantCategoryName: 'Beauty & Wellness',
        merchantSubcategoryID: 30,
        merchantSubcategoryName: 'Massage & Wellness',
        merchantServiceName: 'Hot Stone Massage',
        merchantServiceDescription:
            'Deeply calming treatment that combines warm stones and gentle massage techniques to melt away tension, improve blood flow, and restore balance to the body.',
        amount: 1000,
        ordinal: 5,
        merchantServiceBillingType: 1,
        recommendation: 'per hour',
        baseFair: 0,
        selectionOptions: [],
      ),
      MerchantServiceModel(
        merchantServiceID: 307,
        merchantCategoryID: 1,
        merchantCategoryName: 'Beauty & Wellness',
        merchantSubcategoryID: 30,
        merchantSubcategoryName: 'Massage & Wellness',
        merchantServiceName: 'Ear Candling',
        merchantServiceDescription:
            'Traditional wellness therapy that uses a hollow candle placed in the ear to help remove excess earwax, relieve pressure, and promote relaxation.',
        amount: 300,
        ordinal: 6,
        merchantServiceBillingType: 1,
        recommendation: 'per session',
        baseFair: 0,
        selectionOptions: [],
      ),

      // ─────────────────────────────────────────────────────────────────────
      // NAILS (Subcategory ID: 40)
      // ─────────────────────────────────────────────────────────────────────
      MerchantServiceModel(
        merchantServiceID: 401,
        merchantCategoryID: 1,
        merchantCategoryName: 'Beauty & Wellness',
        merchantSubcategoryID: 40,
        merchantSubcategoryName: 'Nails',
        merchantServiceName: 'Foot Spa',
        merchantServiceDescription:
            'Relaxing foot spa treatment to cleanse, exfoliate, and soften your feet.',
        amount: 350,
        ordinal: 0,
        merchantServiceBillingType: 1,
        recommendation: 'per session',
        baseFair: 0,
        selectionOptions: [],
      ),
      MerchantServiceModel(
        merchantServiceID: 402,
        merchantCategoryID: 1,
        merchantCategoryName: 'Beauty & Wellness',
        merchantSubcategoryID: 40,
        merchantSubcategoryName: 'Nails',
        merchantServiceName: 'Foot Spa with Manicure',
        merchantServiceDescription:
            'Relaxing foot spa combined with a complete manicure service.',
        amount: 500,
        ordinal: 1,
        merchantServiceBillingType: 1,
        recommendation: 'per session',
        baseFair: 0,
        selectionOptions: [],
      ),
      MerchantServiceModel(
        merchantServiceID: 403,
        merchantCategoryID: 1,
        merchantCategoryName: 'Beauty & Wellness',
        merchantSubcategoryID: 40,
        merchantSubcategoryName: 'Nails',
        merchantServiceName: 'Foot Spa with Manicure (Gel)',
        merchantServiceDescription:
            'Relaxing foot spa combined with a gel manicure for long-lasting shine.',
        amount: 700,
        ordinal: 2,
        merchantServiceBillingType: 1,
        recommendation: 'per session',
        baseFair: 0,
        selectionOptions: [],
      ),
      MerchantServiceModel(
        merchantServiceID: 404,
        merchantCategoryID: 1,
        merchantCategoryName: 'Beauty & Wellness',
        merchantSubcategoryID: 40,
        merchantSubcategoryName: 'Nails',
        merchantServiceName: 'Manicure',
        merchantServiceDescription:
            'Nail care, shaping, cuticle grooming, and polish application for beautiful hands.',
        amount: 250,
        ordinal: 3,
        merchantServiceBillingType: 1,
        recommendation: 'per session',
        baseFair: 0,
        selectionOptions: [],
      ),
      MerchantServiceModel(
        merchantServiceID: 405,
        merchantCategoryID: 1,
        merchantCategoryName: 'Beauty & Wellness',
        merchantSubcategoryID: 40,
        merchantSubcategoryName: 'Nails',
        merchantServiceName: 'Pedicure',
        merchantServiceDescription:
            'Complete pedicure service including nail shaping, cuticle care, and polish.',
        amount: 300,
        ordinal: 4,
        merchantServiceBillingType: 1,
        recommendation: 'per session',
        baseFair: 0,
        selectionOptions: [],
      ),
      MerchantServiceModel(
        merchantServiceID: 406,
        merchantCategoryID: 1,
        merchantCategoryName: 'Beauty & Wellness',
        merchantSubcategoryID: 40,
        merchantSubcategoryName: 'Nails',
        merchantServiceName: 'Pedicure (Gel)',
        merchantServiceDescription:
            'Complete pedicure service with gel polish for a long-lasting finish.',
        amount: 450,
        ordinal: 5,
        merchantServiceBillingType: 1,
        recommendation: 'per session',
        baseFair: 0,
        selectionOptions: [],
      ),
      MerchantServiceModel(
        merchantServiceID: 407,
        merchantCategoryID: 1,
        merchantCategoryName: 'Beauty & Wellness',
        merchantSubcategoryID: 40,
        merchantSubcategoryName: 'Nails',
        merchantServiceName: 'Manicure (Gel)',
        merchantServiceDescription:
            'Gel manicure for chip-resistant, high-shine nails that last.',
        amount: 400,
        ordinal: 6,
        merchantServiceBillingType: 1,
        recommendation: 'per session',
        baseFair: 0,
        selectionOptions: [],
      ),
      MerchantServiceModel(
        merchantServiceID: 408,
        merchantCategoryID: 1,
        merchantCategoryName: 'Beauty & Wellness',
        merchantSubcategoryID: 40,
        merchantSubcategoryName: 'Nails',
        merchantServiceName: 'Manicure (Gel Extension)',
        merchantServiceDescription:
            'Gel nail extensions to add length and strength to your natural nails.',
        amount: 800,
        ordinal: 7,
        merchantServiceBillingType: 1,
        recommendation: 'per session',
        baseFair: 0,
        selectionOptions: [],
      ),
      MerchantServiceModel(
        merchantServiceID: 409,
        merchantCategoryID: 1,
        merchantCategoryName: 'Beauty & Wellness',
        merchantSubcategoryID: 40,
        merchantSubcategoryName: 'Nails',
        merchantServiceName: 'Manicure (Acrylic Extension)',
        merchantServiceDescription:
            'Acrylic nail extensions for durable, long-lasting length and style.',
        amount: 900,
        ordinal: 8,
        merchantServiceBillingType: 1,
        recommendation: 'per session',
        baseFair: 0,
        selectionOptions: [],
      ),

      // ─────────────────────────────────────────────────────────────────────
      // LASHES (Subcategory ID: 50)
      // ─────────────────────────────────────────────────────────────────────
      MerchantServiceModel(
        merchantServiceID: 501,
        merchantCategoryID: 1,
        merchantCategoryName: 'Beauty & Wellness',
        merchantSubcategoryID: 50,
        merchantSubcategoryName: 'Lashes',
        merchantServiceName: 'Basic Lash',
        merchantServiceDescription:
            'Classic lash extension for a natural, everyday look with added length and volume.',
        amount: 800,
        ordinal: 0,
        merchantServiceBillingType: 1,
        recommendation: 'per session',
        baseFair: 0,
        selectionOptions: [],
      ),
      MerchantServiceModel(
        merchantServiceID: 502,
        merchantCategoryID: 1,
        merchantCategoryName: 'Beauty & Wellness',
        merchantSubcategoryID: 50,
        merchantSubcategoryName: 'Lashes',
        merchantServiceName: 'Cats-eye Lash',
        merchantServiceDescription:
            'Dramatic cat-eye lash extension style with elongated outer corners for a sultry, lifted look.',
        amount: 1200,
        ordinal: 1,
        merchantServiceBillingType: 1,
        recommendation: 'per session',
        baseFair: 0,
        selectionOptions: [],
      ),

      // ═══════════════════════════════════════════════════════════════════════
      // AIRCON REPAIR (Category ID: 2)
      // ═══════════════════════════════════════════════════════════════════════
      MerchantServiceModel(
        merchantServiceID: 601,
        merchantCategoryID: 2,
        merchantCategoryName: 'Aircon Repair',
        merchantSubcategoryID: 0,
        merchantSubcategoryName: null,
        merchantServiceName: 'Aircon Cleaning',
        merchantServiceDescription:
            'Professional cleaning service for window-type and split-type air conditioning units to improve efficiency and air quality.',
        amount: 500,
        ordinal: 0,
        merchantServiceBillingType: 1,
        recommendation: 'per unit',
        baseFair: 0,
        selectionOptions: [],
      ),
      MerchantServiceModel(
        merchantServiceID: 602,
        merchantCategoryID: 2,
        merchantCategoryName: 'Aircon Repair',
        merchantSubcategoryID: 0,
        merchantSubcategoryName: null,
        merchantServiceName: 'Aircon Check-up & Diagnosis',
        merchantServiceDescription:
            'Comprehensive inspection and diagnosis of aircon issues including refrigerant levels, electrical components, and overall performance.',
        amount: 350,
        ordinal: 1,
        merchantServiceBillingType: 1,
        recommendation: 'per unit',
        baseFair: 0,
        selectionOptions: [],
      ),
      MerchantServiceModel(
        merchantServiceID: 603,
        merchantCategoryID: 2,
        merchantCategoryName: 'Aircon Repair',
        merchantSubcategoryID: 0,
        merchantSubcategoryName: null,
        merchantServiceName: 'Aircon Freon Refill',
        merchantServiceDescription:
            'Refrigerant recharging service to restore cooling efficiency. Includes leak check and system pressure test.',
        amount: 1500,
        ordinal: 2,
        merchantServiceBillingType: 1,
        recommendation: 'per unit',
        baseFair: 0,
        selectionOptions: [],
      ),
      MerchantServiceModel(
        merchantServiceID: 604,
        merchantCategoryID: 2,
        merchantCategoryName: 'Aircon Repair',
        merchantSubcategoryID: 0,
        merchantSubcategoryName: null,
        merchantServiceName: 'Aircon Installation',
        merchantServiceDescription:
            'Professional installation service for new air conditioning units including mounting, piping, and electrical connections.',
        amount: 2500,
        ordinal: 3,
        merchantServiceBillingType: 1,
        recommendation: 'per unit',
        baseFair: 0,
        selectionOptions: [],
      ),
      MerchantServiceModel(
        merchantServiceID: 605,
        merchantCategoryID: 2,
        merchantCategoryName: 'Aircon Repair',
        merchantSubcategoryID: 0,
        merchantSubcategoryName: null,
        merchantServiceName: 'Aircon Repair (Minor)',
        merchantServiceDescription:
            'Minor repairs including fan motor issues, thermostat problems, and minor electrical fixes.',
        amount: 800,
        ordinal: 4,
        merchantServiceBillingType: 1,
        recommendation: 'per unit',
        baseFair: 0,
        selectionOptions: [],
      ),
      MerchantServiceModel(
        merchantServiceID: 606,
        merchantCategoryID: 2,
        merchantCategoryName: 'Aircon Repair',
        merchantSubcategoryID: 0,
        merchantSubcategoryName: null,
        merchantServiceName: 'Aircon Repair (Major)',
        merchantServiceDescription:
            'Major repairs including compressor issues, condenser problems, and complete system overhaul.',
        amount: 2000,
        ordinal: 5,
        merchantServiceBillingType: 1,
        recommendation: 'per unit',
        baseFair: 0,
        selectionOptions: [],
      ),
      MerchantServiceModel(
        merchantServiceID: 607,
        merchantCategoryID: 2,
        merchantCategoryName: 'Aircon Repair',
        merchantSubcategoryID: 0,
        merchantSubcategoryName: null,
        merchantServiceName: 'Aircon Relocation',
        merchantServiceDescription:
            'Safe dismounting, transport, and reinstallation of your air conditioning unit to a new location.',
        amount: 3000,
        ordinal: 6,
        merchantServiceBillingType: 1,
        recommendation: 'per unit',
        baseFair: 0,
        selectionOptions: [],
      ),
    ],
  };

  final Map<String, List<MerchantServiceOptionModel>> _optionsByMerchant = {
    'servana': [
      // Drip Add-Ons for all drip services (101-105)
      MerchantServiceOptionModel(
        merchantOptionID: 1,
        merchantID: 'servana',
        merchantServiceID: 101,
        merchantOptionName: 'Add-ons',
        isRequired: false,
        minimumOption: 0,
        maximumOption: 5,
        ordinal: 0,
        createdDate: DateTime(2024, 1, 1),
        optionItems: const [
          StoreOptionItem(
            merchantOptionItemID: 11,
            merchantOptionID: 1,
            merchantServiceID: '101',
            merchantOptionItemName: 'Vitamin C',
            amount: 350,
            ordinal: 0,
            baseFair: 0,
          ),
          StoreOptionItem(
            merchantOptionItemID: 12,
            merchantOptionID: 1,
            merchantServiceID: '101',
            merchantOptionItemName: 'Vitamin D',
            amount: 350,
            ordinal: 1,
            baseFair: 0,
          ),
          StoreOptionItem(
            merchantOptionItemID: 13,
            merchantOptionID: 1,
            merchantServiceID: '101',
            merchantOptionItemName: 'iSlim (L-Carnitine)',
            amount: 500,
            ordinal: 2,
            baseFair: 0,
          ),
          StoreOptionItem(
            merchantOptionItemID: 14,
            merchantOptionID: 1,
            merchantServiceID: '101',
            merchantOptionItemName: 'Vitamin B Complex',
            amount: 500,
            ordinal: 3,
            baseFair: 0,
          ),
          StoreOptionItem(
            merchantOptionItemID: 15,
            merchantOptionID: 1,
            merchantServiceID: '101',
            merchantOptionItemName: 'Collagen',
            amount: 350,
            ordinal: 4,
            baseFair: 0,
          ),
        ],
      ),
      MerchantServiceOptionModel(
        merchantOptionID: 2,
        merchantID: 'servana',
        merchantServiceID: 102,
        merchantOptionName: 'Add-ons',
        isRequired: false,
        minimumOption: 0,
        maximumOption: 5,
        ordinal: 0,
        createdDate: DateTime(2024, 1, 1),
        optionItems: const [
          StoreOptionItem(
            merchantOptionItemID: 21,
            merchantOptionID: 2,
            merchantServiceID: '102',
            merchantOptionItemName: 'Vitamin C',
            amount: 350,
            ordinal: 0,
            baseFair: 0,
          ),
          StoreOptionItem(
            merchantOptionItemID: 22,
            merchantOptionID: 2,
            merchantServiceID: '102',
            merchantOptionItemName: 'Vitamin D',
            amount: 350,
            ordinal: 1,
            baseFair: 0,
          ),
          StoreOptionItem(
            merchantOptionItemID: 23,
            merchantOptionID: 2,
            merchantServiceID: '102',
            merchantOptionItemName: 'iSlim (L-Carnitine)',
            amount: 500,
            ordinal: 2,
            baseFair: 0,
          ),
          StoreOptionItem(
            merchantOptionItemID: 24,
            merchantOptionID: 2,
            merchantServiceID: '102',
            merchantOptionItemName: 'Vitamin B Complex',
            amount: 500,
            ordinal: 3,
            baseFair: 0,
          ),
          StoreOptionItem(
            merchantOptionItemID: 25,
            merchantOptionID: 2,
            merchantServiceID: '102',
            merchantOptionItemName: 'Collagen',
            amount: 350,
            ordinal: 4,
            baseFair: 0,
          ),
        ],
      ),
      MerchantServiceOptionModel(
        merchantOptionID: 3,
        merchantID: 'servana',
        merchantServiceID: 103,
        merchantOptionName: 'Add-ons',
        isRequired: false,
        minimumOption: 0,
        maximumOption: 5,
        ordinal: 0,
        createdDate: DateTime(2024, 1, 1),
        optionItems: const [
          StoreOptionItem(
            merchantOptionItemID: 31,
            merchantOptionID: 3,
            merchantServiceID: '103',
            merchantOptionItemName: 'Vitamin C',
            amount: 350,
            ordinal: 0,
            baseFair: 0,
          ),
          StoreOptionItem(
            merchantOptionItemID: 32,
            merchantOptionID: 3,
            merchantServiceID: '103',
            merchantOptionItemName: 'Vitamin D',
            amount: 350,
            ordinal: 1,
            baseFair: 0,
          ),
          StoreOptionItem(
            merchantOptionItemID: 33,
            merchantOptionID: 3,
            merchantServiceID: '103',
            merchantOptionItemName: 'iSlim (L-Carnitine)',
            amount: 500,
            ordinal: 2,
            baseFair: 0,
          ),
          StoreOptionItem(
            merchantOptionItemID: 34,
            merchantOptionID: 3,
            merchantServiceID: '103',
            merchantOptionItemName: 'Vitamin B Complex',
            amount: 500,
            ordinal: 3,
            baseFair: 0,
          ),
          StoreOptionItem(
            merchantOptionItemID: 35,
            merchantOptionID: 3,
            merchantServiceID: '103',
            merchantOptionItemName: 'Collagen',
            amount: 350,
            ordinal: 4,
            baseFair: 0,
          ),
        ],
      ),
      MerchantServiceOptionModel(
        merchantOptionID: 4,
        merchantID: 'servana',
        merchantServiceID: 104,
        merchantOptionName: 'Add-ons',
        isRequired: false,
        minimumOption: 0,
        maximumOption: 5,
        ordinal: 0,
        createdDate: DateTime(2024, 1, 1),
        optionItems: const [
          StoreOptionItem(
            merchantOptionItemID: 41,
            merchantOptionID: 4,
            merchantServiceID: '104',
            merchantOptionItemName: 'Vitamin C',
            amount: 350,
            ordinal: 0,
            baseFair: 0,
          ),
          StoreOptionItem(
            merchantOptionItemID: 42,
            merchantOptionID: 4,
            merchantServiceID: '104',
            merchantOptionItemName: 'Vitamin D',
            amount: 350,
            ordinal: 1,
            baseFair: 0,
          ),
          StoreOptionItem(
            merchantOptionItemID: 43,
            merchantOptionID: 4,
            merchantServiceID: '104',
            merchantOptionItemName: 'iSlim (L-Carnitine)',
            amount: 500,
            ordinal: 2,
            baseFair: 0,
          ),
          StoreOptionItem(
            merchantOptionItemID: 44,
            merchantOptionID: 4,
            merchantServiceID: '104',
            merchantOptionItemName: 'Vitamin B Complex',
            amount: 500,
            ordinal: 3,
            baseFair: 0,
          ),
          StoreOptionItem(
            merchantOptionItemID: 45,
            merchantOptionID: 4,
            merchantServiceID: '104',
            merchantOptionItemName: 'Collagen',
            amount: 350,
            ordinal: 4,
            baseFair: 0,
          ),
        ],
      ),
      MerchantServiceOptionModel(
        merchantOptionID: 5,
        merchantID: 'servana',
        merchantServiceID: 105,
        merchantOptionName: 'Add-ons',
        isRequired: false,
        minimumOption: 0,
        maximumOption: 5,
        ordinal: 0,
        createdDate: DateTime(2024, 1, 1),
        optionItems: const [
          StoreOptionItem(
            merchantOptionItemID: 51,
            merchantOptionID: 5,
            merchantServiceID: '105',
            merchantOptionItemName: 'Vitamin C',
            amount: 350,
            ordinal: 0,
            baseFair: 0,
          ),
          StoreOptionItem(
            merchantOptionItemID: 52,
            merchantOptionID: 5,
            merchantServiceID: '105',
            merchantOptionItemName: 'Vitamin D',
            amount: 350,
            ordinal: 1,
            baseFair: 0,
          ),
          StoreOptionItem(
            merchantOptionItemID: 53,
            merchantOptionID: 5,
            merchantServiceID: '105',
            merchantOptionItemName: 'iSlim (L-Carnitine)',
            amount: 500,
            ordinal: 2,
            baseFair: 0,
          ),
          StoreOptionItem(
            merchantOptionItemID: 54,
            merchantOptionID: 5,
            merchantServiceID: '105',
            merchantOptionItemName: 'Vitamin B Complex',
            amount: 500,
            ordinal: 3,
            baseFair: 0,
          ),
          StoreOptionItem(
            merchantOptionItemID: 55,
            merchantOptionID: 5,
            merchantServiceID: '105',
            merchantOptionItemName: 'Collagen',
            amount: 350,
            ordinal: 4,
            baseFair: 0,
          ),
        ],
      ),
    ],
  };

  final List<JobOrder> _bookings = [
    JobOrder(
      jobOrderID: 'jo-001',
      jobOrderNumber: 'JO-00001',
      merchantName: 'Servana',
      scheduleDate: DateTime.now().add(const Duration(days: 1)),
      jobOrderStatusToString: 'Accepted',
      jobOrderStatus: JobOrderStatus.accepted,
      merchantID: 'servana',
      address: 'Makati, Metro Manila',
      numberOfPersonnel: 1,
      distanceFromOffice: 3,
      merchantServiceName: 'Signature Facial',
      latitude: 14.5547,
      longitude: 121.0244,
      downPayment: 0,
      totalAmount: 2000,
      paymentType: 1,
      createdDate: DateTime.now().subtract(const Duration(days: 1)),
    ),
    JobOrder(
      jobOrderID: 'jo-002',
      jobOrderNumber: 'JO-00002',
      merchantName: 'Servana',
      scheduleDate: DateTime.now().add(const Duration(days: 3, hours: 2)),
      jobOrderStatusToString: 'For Review',
      jobOrderStatus: JobOrderStatus.forReview,
      merchantID: 'servana',
      address: 'BGC, Taguig',
      numberOfPersonnel: 1,
      distanceFromOffice: 5,
      merchantServiceName: 'Body Massage',
      latitude: 14.5534,
      longitude: 121.0509,
      downPayment: 0,
      totalAmount: 400,
      paymentType: 1,
      createdDate: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    JobOrder(
      jobOrderID: 'jo-003',
      jobOrderNumber: 'JO-00003',
      merchantName: 'Servana',
      scheduleDate: DateTime.now().add(const Duration(days: 7, hours: 1)),
      jobOrderStatusToString: 'Accepted',
      jobOrderStatus: JobOrderStatus.accepted,
      merchantID: 'servana',
      address: 'Ortigas, Pasig',
      numberOfPersonnel: 2,
      distanceFromOffice: 8,
      merchantServiceName: 'Hydra Facial',
      latitude: 14.5869,
      longitude: 121.0614,
      downPayment: 0,
      totalAmount: 3500,
      paymentType: 1,
      createdDate: DateTime.now().subtract(const Duration(days: 2)),
    ),
    JobOrder(
      jobOrderID: 'jo-004',
      jobOrderNumber: 'JO-00004',
      merchantName: 'Servana',
      scheduleDate: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
      jobOrderStatusToString: 'Completed',
      jobOrderStatus: JobOrderStatus.completed,
      merchantID: 'servana',
      address: 'Mandaluyong City',
      numberOfPersonnel: 1,
      distanceFromOffice: 4,
      merchantServiceName: 'Foot Spa',
      latitude: 14.5794,
      longitude: 121.0359,
      downPayment: 0,
      totalAmount: 350,
      paymentType: 1,
      createdDate: DateTime.now().subtract(const Duration(days: 4)),
      dateEnd: DateTime.now().subtract(const Duration(days: 2, hours: 1)),
    ),
  ];

  @override
  Future<({UserSession? session, String? error, int? statusCode})>
      authenticate({
    required String email,
    required String password,
    String fcmToken = '',
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    if (email.trim().isEmpty || password.trim().isEmpty) {
      return (
        session: null,
        error: 'Email and password are required.',
        statusCode: 400,
      );
    }
    return (
      session: UserSession(
        customerID: 'cust-001',
        mobileNumber: email,
        fullname: 'Mock User',
        emailAddress: email,
        token: 'mock-token',
      ),
      error: null,
      statusCode: 200,
    );
  }

  @override
  Future<({bool isSuccess, String? message, int? statusCode})> registerCustomer(
      RegistrationFormModel registration) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return (
      isSuccess: true,
      message: 'Registration submitted (mock).',
      statusCode: 200,
    );
  }

  @override
  Future<List<MerchantLight>> getNearbyMerchants(
      {required double latitude, required double longitude}) async {
    await Future.delayed(const Duration(milliseconds: 250));
    // Ratings come from backend-authoritative aggregates, not mocked.
    return List.of(_merchants);
  }

  @override
  Future<List<JobOrder>> getBookings({required String customerId}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List<JobOrder>.unmodifiable(_bookings);
  }

  @override
  Future<List<SearchServiceResult>> searchService(
      {required String keyword}) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final q = keyword.trim().toLowerCase();
    if (q.isEmpty) return [];

    final results = <SearchServiceResult>[];
    for (final merchant in _merchants) {
      final services = _servicesByMerchant[merchant.merchantID] ?? const [];
      for (final s in services) {
        if (merchant.merchantName.toLowerCase().contains(q) ||
            s.merchantServiceName.toLowerCase().contains(q)) {
          results.add(
            SearchServiceResult(
              merchantID: merchant.merchantID,
              merchantName: merchant.merchantName,
              merchantStatus: merchant.merchantStatus,
              merchantStatusToString: merchant.merchantStatusToString,
              city: merchant.city,
              barangay: '—',
              longitude: merchant.longitude,
              latitude: merchant.latitude,
              rating: merchant.rating,
              listImage: merchant.listImage ?? '',
              merchantServiceID: s.merchantServiceID,
              merchantServiceName: s.merchantServiceName,
              amount: s.amount.toDouble(),
              merchantServicePictureURL: s.merchantServicePictureURL,
              discounts: merchant.discounts,
            ),
          );
        }
      }
    }
    return results;
  }

  @override
  Future<MerchantModel?> getMerchantDetails({required String id}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _merchantDetails[id];
  }

  @override
  Future<JobOrderDetails?> getMerchantJoDetails({required String id}) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final booking = _bookings.firstWhere(
      (b) => b.jobOrderID == id,
      orElse: () => _bookings.first,
    );
    return JobOrderDetails(
      jobOrderID: booking.jobOrderID,
      customerID: 'cust-001',
      merchantID: booking.merchantID,
      jobOrderNumber: booking.jobOrderNumber,
      jobOrderStatus: booking.jobOrderStatus,
      scheduleDate: booking.scheduleDate,
      dateStart: booking.dateStart,
      dateEnd: booking.dateEnd,
      actualDateStart: booking.actualDateStart,
      actualDateEnd: booking.actualDateEnd,
      address: booking.address,
      latitude: booking.latitude,
      longitude: booking.longitude,
      note: booking.note ?? '',
      numberOfPersonnel: booking.numberOfPersonnel,
      paymentType: booking.paymentType,
      totalAmount: booking.totalAmount,
      downPayment: booking.downPayment,
      createdDate: booking.createdDate,
    );
  }

  @override
  Future<List<JobOrderItem>> getJobOrderItems({required String id}) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return const [
      JobOrderItem(
        jobOrderItemID: 1,
        serviceId: '205',
        serviceName: 'Signature Facial',
        quantity: 1,
        amount: 2000,
        discount: 0,
        transportaion: 0,
        selectedOptions: [],
      ),
    ];
  }

  @override
  Future<List<MerchantUser>> getJobOrderEmployees({required String id}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const [
      MerchantUser(
        merchantUserID: 'emp-001',
        merchantUserRoleType: 1,
        jobOrderPersonnelID: 1,
        contactNumber: '+63 900 000 1234',
        merchantUserStatus: 1,
        profilePictureURL: '',
        fullname: 'Juan Dela Cruz',
      ),
    ];
  }

  @override
  Future<List<MerchantServiceModel>> getServices(
      {required String merchantId}) async {
    await Future.delayed(const Duration(milliseconds: 250));
    if (merchantId.trim().isEmpty) {
      return List<MerchantServiceModel>.unmodifiable(
        _servicesByMerchant.values.expand((e) => e).toList(),
      );
    }
    return List<MerchantServiceModel>.unmodifiable(
      _servicesByMerchant[merchantId] ?? const [],
    );
  }

  @override
  Future<List<MerchantServiceOptionModel>> getMerchantOptions(
      {required String merchantId}) async {
    await Future.delayed(const Duration(milliseconds: 250));
    if (merchantId.trim().isEmpty) {
      return List<MerchantServiceOptionModel>.unmodifiable(
        _optionsByMerchant.values.expand((e) => e).toList(),
      );
    }
    return List<MerchantServiceOptionModel>.unmodifiable(
      _optionsByMerchant[merchantId] ?? const [],
    );
  }

  @override
  Future<List<({int key, String value})>> getCategories(
      {required String merchantId}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final services = merchantId.trim().isEmpty
        ? _servicesByMerchant.values.expand((e) => e).toList()
        : (_servicesByMerchant[merchantId] ?? const []);
    final seen = <int>{};
    final cats = <({int key, String value})>[];
    for (final s in services) {
      if (seen.add(s.merchantCategoryID)) {
        cats.add(
            (key: s.merchantCategoryID, value: s.merchantCategoryName ?? ''));
      }
    }
    return cats;
  }

  @override
  Future<bool> toggleService({required String id, required bool isOn}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return true;
  }

  @override
  Future<bool> addService({required MerchantServiceModel service}) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return true;
  }

  @override
  Future<({bool isSuccess, String? error})> editService(
      {required MerchantServiceModel service}) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return (isSuccess: true, error: null);
  }

  @override
  Future<bool> addServiceCategory({required MerchantCategory category}) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return true;
  }

  @override
  Future<bool> insertJobOrder({
    required String merchantId,
    required String address,
    String? note,
    required DateTime schedule,
    required LatLng coords,
    required List<JobOrderItem> items,
    required List<StoreOptionItem> options,
    String? customerId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final merchant = _merchants.firstWhere((m) => m.merchantID == merchantId,
        orElse: () => _merchants.first);
    final id = 'jo-${_rng.nextInt(9000) + 1000}';
    _bookings.insert(
      0,
      JobOrder(
        jobOrderID: id,
        jobOrderNumber: 'JO-${_rng.nextInt(90000) + 10000}',
        merchantName: merchant.merchantName,
        scheduleDate: schedule,
        jobOrderStatusToString: 'Accepted',
        jobOrderStatus: JobOrderStatus.accepted,
        merchantID: merchantId,
        address: address,
        numberOfPersonnel: 1,
        distanceFromOffice: 3,
        merchantServiceName:
            items.isNotEmpty ? items.first.serviceName : 'Service',
        latitude: coords.latitude,
        longitude: coords.longitude,
        note: note,
        downPayment: 0,
        totalAmount: items.fold<double>(0, (p, e) => p + e.amount),
        paymentType: 1,
        createdDate: DateTime.now(),
      ),
    );
    return true;
  }

  @override
  Future<bool> markAsCompleted({required String id}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _bookings.indexWhere((b) => b.jobOrderID == id);
    if (idx == -1) return false;
    final b = _bookings[idx];
    _bookings[idx] = b.copyWith(
      jobOrderStatus: JobOrderStatus.completed,
      jobOrderStatusToString: 'Completed',
      dateEnd: DateTime.now(),
    );
    return true;
  }

  @override
  Future<({bool isSuccess, String? message})> addUserAddress(
          UserAddressModel address) =>
      throw UnimplementedError('addUserAddress requires HttpBackend');

  @override
  Future<({bool isSuccess, String? message})> makeAddressPrimary(
          {required String addressId}) =>
      throw UnimplementedError('makeAddressPrimary requires HttpBackend');

  @override
  Future<ServiceCoverageGeo?> getServiceCoverageGeo(
          {required String serviceId}) =>
      throw UnimplementedError('getServiceCoverageGeo requires HttpBackend');

  @override
  Future<({bool isSuccess, String? message, int? statusCode})>
      resendVerificationEmail({required String email}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return (
      isSuccess: true,
      message: 'Verification email sent (mock).',
      statusCode: 200,
    );
  }

  @override
  Future<void> logout() async {}
}
