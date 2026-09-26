import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryService {
  static final Map<String, IconData> iconOptions = {
    'restaurant': Icons.restaurant_rounded,
    'car': Icons.directions_car_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'receipt': Icons.receipt_long_rounded,
    'movie': Icons.movie_rounded,
    'home': Icons.home_rounded,
    'health': Icons.health_and_safety_rounded,
    'school': Icons.school_rounded,
    'phone': Icons.phone_android_rounded,
    'game': Icons.sports_esports_rounded,
    'travel': Icons.flight_rounded,
    'coffee': Icons.coffee_rounded,
    'gift': Icons.card_giftcard_rounded,
    'pets': Icons.pets_rounded,
    'fitness': Icons.fitness_center_rounded,
    'music': Icons.music_note_rounded,
    'work': Icons.work_rounded,
    'wallet': Icons.account_balance_wallet_rounded,
    'category': Icons.category_outlined,
    'more': Icons.more_horiz_rounded,
  };

  static final List<Map<String, dynamic>>
      defaultCategories = [
    {
      'name': 'Makanan',
      'iconKey': 'restaurant',
      'icon': Icons.restaurant_rounded,
      'isCustom': false,
    },
    {
      'name': 'Transportasi',
      'iconKey': 'car',
      'icon': Icons.directions_car_rounded,
      'isCustom': false,
    },
    {
      'name': 'Belanja',
      'iconKey': 'shopping',
      'icon': Icons.shopping_bag_rounded,
      'isCustom': false,
    },
    {
      'name': 'Tagihan',
      'iconKey': 'receipt',
      'icon': Icons.receipt_long_rounded,
      'isCustom': false,
    },
    {
      'name': 'Hiburan',
      'iconKey': 'movie',
      'icon': Icons.movie_rounded,
      'isCustom': false,
    },
    {
      'name': 'Lainnya',
      'iconKey': 'more',
      'icon': Icons.more_horiz_rounded,
      'isCustom': false,
    },
  ];

  static final List<Map<String, dynamic>>
      customCategories = [];

  static const String _storageKey =
      'custom_categories';

  static List<Map<String, dynamic>>
      get categories {
    return [
      ...defaultCategories,
      ...customCategories,
    ];
  }

  static Future<void> loadCategories() async {
    final prefs =
        await SharedPreferences.getInstance();

    final String? data =
        prefs.getString(_storageKey);

    if (data == null || data.isEmpty) {
      return;
    }

    try {
      final List<dynamic> decoded =
          jsonDecode(data);

      customCategories.clear();

      for (final item in decoded) {
        final String name =
            item['name']?.toString() ?? '';

        final String iconKey =
            item['iconKey']?.toString() ??
                'category';

        if (name.isEmpty) {
          continue;
        }

        customCategories.add({
          'name': name,
          'iconKey': iconKey,
          'icon':
              iconOptions[iconKey] ??
                  Icons.category_outlined,
          'isCustom': true,
        });
      }
    } catch (e) {
      customCategories.clear();
    }
  }

  static Future<bool> addCategory(
    String name, {
    String iconKey = 'category',
  }) async {
    final String categoryName =
        name.trim();

    if (categoryName.isEmpty) {
      return false;
    }

    final bool defaultExists =
        defaultCategories.any(
      (category) =>
          category['name']
              .toString()
              .toLowerCase() ==
          categoryName.toLowerCase(),
    );

    final bool customExists =
        customCategories.any(
      (category) =>
          category['name']
              .toString()
              .toLowerCase() ==
          categoryName.toLowerCase(),
    );

    if (defaultExists ||
        customExists) {
      return false;
    }

    customCategories.add({
      'name': categoryName,
      'iconKey': iconKey,
      'icon':
          iconOptions[iconKey] ??
              Icons.category_outlined,
      'isCustom': true,
    });

    await _saveCategories();

    return true;
  }

  static Future<void> deleteCategory(
    String name,
  ) async {
    customCategories.removeWhere(
      (category) =>
          category['name'] == name,
    );

    await _saveCategories();
  }

  static bool isCustomCategory(
    String name,
  ) {
    return customCategories.any(
      (category) =>
          category['name'] == name,
    );
  }

  static Future<void>
      _saveCategories() async {
    final prefs =
        await SharedPreferences.getInstance();

    final List<Map<String, dynamic>>
        data =
        customCategories.map(
      (category) {
        return {
          'name': category['name'],
          'iconKey':
              category['iconKey'] ??
                  'category',
        };
      },
    ).toList();

    await prefs.setString(
      _storageKey,
      jsonEncode(data),
    );
  }
}