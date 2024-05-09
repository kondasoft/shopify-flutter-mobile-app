import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ProductBuyItNow extends StatefulWidget {
	final String checkoutUrl;

  const ProductBuyItNow({super.key, required this.checkoutUrl});

  @override
  State<ProductBuyItNow> createState() => _ProductBuyItNowState();
}

class _ProductBuyItNowState extends State<ProductBuyItNow> {
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