import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'cart_model.dart';
import 'cart_empty.dart';
import 'cart_line_item.dart';
import 'cart_checkout.dart';

class CartPage extends StatefulWidget {

	const CartPage({super.key});

	@override
	State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {

	@override
	void initState() {
		super.initState();
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('Cart'),
			),
			body: context.read<CartModel>().count == 0
				? const CartEmpty()
				: Column(
					children: [
						Expanded(
							child: ListView(
								padding: const EdgeInsets.fromLTRB(8, 10, 8, 16),
								children: [
									for (dynamic edge in context.watch<CartModel>().cart!['lines']['edges'])
										CartLineItem(
											key: Key(edge['node']['id']),
											lineItem: edge['node'],
										)
								],
							)
						),
						Divider(height: 1, color: Theme.of(context).primaryColor.withOpacity(.3)),
						Container(
							color: Theme.of(context).primaryColor.withOpacity(.1),
							padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
							width: MediaQuery.of(context).size.width,
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.center,
								children: [
									Row(
										mainAxisAlignment: MainAxisAlignment.spaceBetween,
										children: [
											const Text('Subtotal:', style: TextStyle(fontSize: 16),),
											Text('\$${context.watch<CartModel>().cart!['cost']['subtotalAmount']['amount']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),)
										],
									),
									const SizedBox(height: 6),
									ElevatedButton(
										onPressed: () async {
											await Future.delayed(const Duration(milliseconds: 200));
											if (context.mounted) {
												Navigator.of(context).push(MaterialPageRoute(builder: (context) => CartCheckoout(checkoutUrl: context.read<CartModel>().cart!['checkoutUrl'],)));
											}
										},
										style: ButtonStyle(
											padding: MaterialStateProperty.all(
												const EdgeInsets.symmetric(vertical: 10),
											),
											backgroundColor: MaterialStateProperty.all(Theme.of(context).primaryColor),
											foregroundColor: MaterialStateProperty.all(Colors.white),
											overlayColor: MaterialStateProperty.all(Colors.white.withOpacity(.25)),
										),
										child: const Row(
											mainAxisAlignment: MainAxisAlignment.center,
											children: [
												Icon(Icons.lock_outline_rounded, size: 20),
												SizedBox(width: 8),
												Text('Checkout', style: TextStyle(fontSize: 16),),
											],
										)
									),
									const SizedBox(height: 4),
									const Text('Taxes & Shipping calculated at checkout', style: TextStyle(fontSize: 12, color: Colors.blueGrey),),		
									const SizedBox(height: 8),
								],
							)
						)
					]
				)
		);
	}
}