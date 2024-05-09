import 'package:flutter/material.dart';

class CartEmpty extends StatefulWidget {
	const CartEmpty({super.key});

	@override
	State<CartEmpty> createState() => _CartEmptyState();
}

class _CartEmptyState extends State<CartEmpty> with SingleTickerProviderStateMixin {
  	late AnimationController _controller;

	@override
	void initState() {
		super.initState();
		_controller = AnimationController(duration: const Duration(seconds: 1), vsync: this)
			..repeat(reverse: true);
	}
	
	@override
	void dispose() {
		_controller.dispose();
		super.dispose();
	}
	
	@override
	Widget build(BuildContext context) {
		return Center(
			child: Column(
				mainAxisAlignment: MainAxisAlignment.center,
				children: [
					AnimatedBuilder(
						animation: _controller,
						builder: (context, child) => Transform.translate(
							offset: Offset(-5 + (_controller.value * 10), 0),
							child: child,
						),
						child: const Icon(Icons.shopping_bag_outlined, size: 28, color: Colors.grey,),
					),
					const SizedBox(height: 12),
					const Text('Your cart is currently empty'),
					const SizedBox(height: 16),
					ElevatedButton(
						onPressed: () {
							Future.delayed(const Duration(milliseconds: 200)).then((_) => {
								Navigator.of(context).pop()
							});
						},
						child: const Text('Continue Shopping'),
					)
				],
			),
		);
	}
}