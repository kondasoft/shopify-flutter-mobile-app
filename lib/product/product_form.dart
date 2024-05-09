import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../cart/cart.dart';
import '../cart/cart_model.dart';
import 'product_selected_variant_model.dart';
import 'product_buy_it_now.dart';

class ProductForm extends StatefulWidget {
	final Map product;

	const ProductForm({super.key, required this.product});

	@override
	State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
	int _qty = 1;
	bool _loading = false;

	Map get _selectedVariant =>
		context.read<SelectedVariantModel>().selectedVariant 
			?? widget.product['variants']['edges'][0]['node'];

	double? get _compareAtPrice {
		if (_selectedVariant['compareAtPrice'] == null) {
			return null;
		}

		return double.parse(_selectedVariant['compareAtPrice']['amount']);
	}

	double get _price {
		return double.parse(_selectedVariant['price']['amount']);
	}

	@override
	void initState() {
		super.initState();
	}

	@override
	Widget build(BuildContext context) {
		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [ 
				Row(
					mainAxisAlignment: MainAxisAlignment.center,
					children: [
						if (_compareAtPrice != null)
							Padding(
								padding: const EdgeInsets.only(right: 6),
								child: Text('\$$_compareAtPrice', style: const TextStyle(fontSize: 16, color: Colors.blueGrey, decoration: TextDecoration.lineThrough))
							),
						Text('\$$_price', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: Colors.blueGrey))
					],
				),
				const SizedBox(height: 12),
				for (MapEntry optionEntry in widget.product['options'].asMap().entries)
					Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Text(optionEntry.value['name'], style: const TextStyle(fontWeight: FontWeight.w500),),
							Wrap(
								spacing: 6,
								runSpacing: 0,
								children: [
									for (String optionValue in optionEntry.value['values'])
										OutlinedButton(
											onPressed: () {
												// TODO: Variant switcher don't work on tablet
												List<String> selectedOptions = List.from(_selectedVariant['selectedOptions']).map<String>((element) =>
													element['value']).toList();
									
												selectedOptions[optionEntry.key] = optionValue;

												Map? newVariant;

												for (Map edge in widget.product['variants']['edges']) {
													List<String> optionsFound = List.from(edge['node']['selectedOptions']).map<String>((element) =>
														element['value']).toList();

													if (listEquals(selectedOptions, optionsFound)) {
														newVariant = edge['node'];
													}
												}

												if (newVariant == null) {
													ScaffoldMessenger.of(context)
														.showSnackBar(SnackBar(
															content: Text('Sorry! The variant with options ${selectedOptions.toString()} is not available')
														));
													return;
												}

												context.read<SelectedVariantModel>().setSelectedVariant(newVariant);
											}, 
											style: ButtonStyle(
												side:  MaterialStateProperty.all(BorderSide(
													color: optionValue == _selectedVariant['selectedOptions'][optionEntry.key]['value'] ? Theme.of(context).primaryColor.withOpacity(1) : Theme.of(context).primaryColor.withOpacity(.2),
												)),
												overlayColor:  MaterialStateProperty.resolveWith<Color>((states) {
													if (states.contains(MaterialState.pressed)) {
														return Theme.of(context).primaryColor.withOpacity(.1);
													}
													return Colors.transparent;
												}),
												foregroundColor: MaterialStateProperty.all(Theme.of(context).primaryColor),
												backgroundColor: optionValue == _selectedVariant['selectedOptions'][optionEntry.key]['value'] ? MaterialStateProperty.all(Theme.of(context).primaryColor.withOpacity(.1)) : MaterialStateProperty.all(Colors.white)
											),
											child: Text(optionValue, style: const TextStyle(fontSize: 13))
										),
								],
							),
							const SizedBox(height: 10),
						],
					),
				const SizedBox(height: 8),
				Row (
					children: [
						Container(
							decoration: BoxDecoration(
								color: Colors.white,
								border: Border.all(color: Theme.of(context).primaryColor),
								borderRadius: BorderRadius.circular(24)
							),
							child: Row(
								mainAxisSize: MainAxisSize.min,
								children: [
									SizedBox(
										width: 38,
										height: 38,
										child: RawMaterialButton(
											onPressed: () {
												if (_qty > 1) {
													setState(() {
														_qty -= 1;	
													});
												}
											},
											shape: const CircleBorder(),
											child: Icon(Icons.remove, size: 16, color: Theme.of(context).primaryColor,),
										),
									),
									SizedBox(
										width: 32,
										child: TextField(
											controller: TextEditingController(
												text: _qty.toString()
											),
											decoration: const InputDecoration(
												border: InputBorder.none,
												hintText: 'QTY',
												isDense: true,
												contentPadding: EdgeInsets.fromLTRB(0, 4, 0, 4),
											),
											style: TextStyle(fontSize: 14, color: Theme.of(context).primaryColor),
											keyboardType: TextInputType.number,
											textAlign: TextAlign.center,
											onChanged: (value) {
												if (value.isNotEmpty && int.parse(value) > 1) {
													setState(() {
														_qty = int.parse(value);
													});
												}
											},
										),
									),
									SizedBox(
										width: 38,
										height: 38,
										child: RawMaterialButton(
											onPressed: () {
												setState(() {
													_qty += 1;	
												});
											},
											shape: const CircleBorder(),
											child: Icon(Icons.add, size: 16, color: Theme.of(context).primaryColor,),
										),
									),
								],
							),
						),
						const SizedBox(width: 8),
						Expanded(
							child: TextButton(
								onPressed: _selectedVariant['availableForSale'] ? () async {
									setState(() {
									  	_loading = true;
									});
									
									await context.read<CartModel>().cartLinesAdd(context, [
										{
											'merchandiseId': _selectedVariant['id'],
											'quantity':  _qty
										}
									]);

									setState(() {
									  	_loading = false;
									});

									if (context.mounted) {
										ScaffoldMessenger.of(context)
											.showSnackBar(SnackBar(
												content: Text('${widget.product['title']} was successfully added to your cart!'),
												action: SnackBarAction(
													label: 'View cart',
													onPressed: () async {
														await Future.delayed(const Duration(milliseconds: 200));
														if (context.mounted) {
															Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CartPage()));
														}
													},
												),
											));
									}
									
								} : null,
								style: ButtonStyle(
									backgroundColor: MaterialStateProperty.all(Theme.of(context).primaryColor),
									foregroundColor: MaterialStateProperty.all(Colors.white),
									overlayColor: MaterialStateProperty.all(Colors.white.withOpacity(.25)),
								),
								child: _loading
									?  const SizedBox(
											height: 19,
											width: 19,
											child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,),
										)
									: Text(
										_selectedVariant['availableForSale'] ? 'Add to cart' : 'Sold out', 
										style: const TextStyle(fontSize: 15),),
							)
						)
					],
				),
				const SizedBox(height: 4),
				SizedBox(
					width: double.infinity,
					child: OutlinedButton(
						onPressed: _selectedVariant['availableForSale'] ? () async {
							await Future.delayed(const Duration(milliseconds: 200));
							if (context.mounted) {
								final id = _selectedVariant['id'].split('Variant/')[1];
								Navigator.of(context).push(MaterialPageRoute(builder: (context) => 
									ProductBuyItNow(checkoutUrl: '${dotenv.env['PRIMARY_DOMAIN']}/cart/$id:$_qty')));
							}
						} : null,
						style: ButtonStyle(
							side:  MaterialStateProperty.all(BorderSide(
								color: _selectedVariant['availableForSale'] ? Theme.of(context).primaryColor : Theme.of(context).primaryColor.withOpacity(.2)
							))
						),
						child: Text('Buy it now', style: TextStyle(fontSize: 15, color: Theme.of(context).primaryColor)),
					),
				)
			]
		);
	}
}