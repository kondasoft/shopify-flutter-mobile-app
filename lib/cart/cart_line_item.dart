
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import 'cart_model.dart';
import '../product/product.dart';

class CartLineItem extends StatefulWidget {
	final Map lineItem;

	const CartLineItem({super.key, required this.lineItem});

	@override
	State<CartLineItem> createState() => _CartLineItemState();
}

class _CartLineItemState extends State<CartLineItem> {
	bool _cardLoading = false;
	late int _qty;

	Future<void> _updateQuantity (int qty) async {
		setState(() {
			_cardLoading = true;
			_qty = qty;
		});
		await context.read<CartModel>().cartLinesUpdate(context, widget.lineItem['id'], qty);
		setState(() {
			_cardLoading = false;
		});
	}

	@override
	void initState() {
		super.initState();
		_qty = widget.lineItem['quantity'];
  	}

	@override
	Widget build(BuildContext context) {
		return Dismissible(
			key: Key(widget.lineItem['id']),
			onDismissed: (direction) {
				context.read<CartModel>().cartLinesRemove(context, widget.lineItem['id']);
			},
			direction: DismissDirection.endToStart,
			background: Container(
				decoration: BoxDecoration(
					color: Colors.red.shade700,
					borderRadius: BorderRadius.circular(4),
				),
				padding: const EdgeInsets.only(right: 16),
				margin: const EdgeInsets.all(6),
				child: const Align(
					alignment: Alignment.centerRight,
					child: Icon(Icons.delete, color: Colors.white),
				)
			),
			child: AnimatedOpacity(
				opacity: _cardLoading ? .25 : 1,
				duration: const Duration(milliseconds: 200),
				child: Card(
					margin: const EdgeInsets.all(6),
					child: Row(
						children: [
							Stack(
								children: <Widget>[
									SizedBox(
										width: MediaQuery.of(context).size.width / 3.5,
										height: MediaQuery.of(context).size.width / 3.5,
										child: CachedNetworkImage(
											imageUrl: widget.lineItem['merchandise']['image']['transformedSrc'] ?? '',
											placeholder: (context, url) => Container(
												color: Colors.grey.shade100,
											),
										),
									),
									Positioned.fill(
										child: Material(
											color: Colors.transparent,
											child: InkWell(
												onTap: () {
													Future.delayed(const Duration(milliseconds: 200)).then((_) => {
														Navigator.of(context).push(MaterialPageRoute(builder: (context) => ProductPage(
															id: widget.lineItem['merchandise']['product']['id'],
															title: widget.lineItem['merchandise']['product']['title'],
														)))
													});
												},
											)
										)
									) 
								]
							),
							Expanded( 
								child: Padding(
									padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											Row(
												mainAxisAlignment: MainAxisAlignment.spaceBetween,
												children: [
													Flexible(
														child: InkWell(
															onTap: () {
																Future.delayed(const Duration(milliseconds: 200)).then((_) => {
																	Navigator.of(context).push(MaterialPageRoute(builder: (context) => ProductPage(
																		id: widget.lineItem['merchandise']['product']['id'],
																		title: widget.lineItem['merchandise']['product']['title'],
																	)))
																});
															},
															child: Text(widget.lineItem['merchandise']['product']['title'], overflow: TextOverflow.ellipsis, style: const TextStyle()),
														)
													),
													Padding(
														padding: const EdgeInsets.only(left: 8),
														child: Text('\$${widget.lineItem['cost']['amountPerQuantity']['amount']}', style: const TextStyle(color: Colors.blueGrey)),
													),
												]
											),
											const SizedBox(height: 2),
											Text(widget.lineItem['merchandise']['title'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
											const SizedBox(height: 10),
											Container(
												decoration: BoxDecoration(
													border: Border.all(color: Colors.grey.shade200),
													borderRadius: BorderRadius.circular(20)
												),
												child: Row(
													mainAxisSize: MainAxisSize.min,
													children: [
														SizedBox(
															width: 30,
															height: 30,
															child: RawMaterialButton(
																onPressed: () {
																	_updateQuantity(_qty -= 1);
																},
																shape: const CircleBorder(),
																child: const Icon(Icons.remove, size: 14,),
															),
														),
														SizedBox(
															width: 30,
															child: TextField(
																controller: TextEditingController(
																	text: _qty.toString()
																),
																decoration: const InputDecoration(
																	border: InputBorder.none,
																	hintText: 'QTY',
																	isDense: true,
																	contentPadding: EdgeInsets.fromLTRB(0, 8, 0, 6),
																),
																style: const TextStyle(fontSize: 13),
																keyboardType: TextInputType.number,
																textAlign: TextAlign.center,
																onChanged: (value) {
																	if (value.isNotEmpty && int.parse(value) >= 0) {
																		_updateQuantity(_qty = int.parse(value));
																	}
																},
															),
														),
														SizedBox(
															width: 30,
															height: 30,
															child: RawMaterialButton(
																onPressed: () {
																	_updateQuantity(_qty += 1);
																},
																shape: const CircleBorder(),
																child: const Icon(Icons.add, size: 14,),
															),
														),
													],
												)
											)
										],
									),
								),
							),
						],
					),
				)
			)
		);
	}
}