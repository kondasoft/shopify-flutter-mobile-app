import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CartCheckoout extends StatefulWidget {
	final String checkoutUrl;

  const CartCheckoout({super.key, required this.checkoutUrl});

  @override
  State<CartCheckoout> createState() => _CartCheckooutState();
}

class _CartCheckooutState extends State<CartCheckoout> {
	late final WebViewController _controller;

	 @override
		void initState() {
			super.initState();
			_controller = WebViewController()
				..loadRequest(
					Uri.parse(widget.checkoutUrl),
				);
		}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: WebViewWidget(
        controller: _controller,
      ),
    );
  }
}