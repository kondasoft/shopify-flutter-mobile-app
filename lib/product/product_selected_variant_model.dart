import 'package:flutter/material.dart';

class SelectedVariantModel with ChangeNotifier {
	Map? _selectedVariant;

	Map? get selectedVariant => _selectedVariant;

	void setSelectedVariant(Map? variant) async {
		print(variant!['id']);
		_selectedVariant = variant;
		notifyListeners();
  	}
}
