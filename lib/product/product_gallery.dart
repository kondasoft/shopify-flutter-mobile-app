import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';

import 'product_selected_variant_model.dart';

class ProductGallery extends StatefulWidget {
	final Map product;

	const ProductGallery({super.key, required this.product});

	@override
	State<ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<ProductGallery> {
	int _currentSlide = 0;
	final CarouselController _controller = CarouselController();

	@override
	void initState() {
		super.initState();

		if (mounted) {
			final selectedVariant = context.read<SelectedVariantModel>().selectedVariant;

			if (selectedVariant != null) {
				for (MapEntry mapEntry in widget.product['images']['edges'].asMap().entries) {
					if (mapEntry.value['node']['id'] == selectedVariant['image']['id']) {
						if (mapEntry.value['node']['id'] == selectedVariant['image']['id']) {
							_currentSlide = mapEntry.key;
						}
					}
				}
			}
		}

		Provider.of<SelectedVariantModel>(context, listen: false).addListener(() {
			if (mounted) {
				final selectedVariant = context.read<SelectedVariantModel>().selectedVariant;

				if (selectedVariant != null) {
					for (MapEntry mapEntry in widget.product['images']['edges'].asMap().entries) {
						if (mapEntry.value['node']['id'] == selectedVariant['image']['id']) {
							_controller.animateToPage(mapEntry.key);
						}
					}
				}
			}
		});
	}

	@override
	Widget build(BuildContext context) {
		return Stack(
			children: [
				CarouselSlider(
					options: CarouselOptions (
						initialPage: _currentSlide,
						aspectRatio: 1,
						viewportFraction: 1,
						onPageChanged: (index, reason) {
							setState(() {
								_currentSlide = index;
							});
						}
					),
					carouselController: _controller,
					items: widget.product['images']['edges'].map<Widget>((item) => 
						CachedNetworkImage(
							imageUrl: item['node']['transformedSrc'] ?? '',
							placeholder: (context, url) => Container(
								color: Colors.grey.shade100,
							),
							width: MediaQuery.of(context).size.width,
							height: MediaQuery.of(context).size.width,
							fit: BoxFit.cover,
						)
					).toList(),
				),
				Positioned(
					bottom: 12,
					child: 
						SizedBox(
							width: MediaQuery.of(context).size.width,
							child: Row(
							mainAxisAlignment: MainAxisAlignment.center,
							children: widget.product['images']['edges'].asMap().entries.map<Widget>((entry) =>
								Container(
									width: 6,
									height: 6,
									margin: const EdgeInsets.all(3),
									decoration: BoxDecoration(
										shape: BoxShape.circle,
										color: Colors.black.withOpacity(_currentSlide == entry.key ? 0.5 : 0.1)
									)
								),
							).toList(),
						)
					),
				),
			]
		);
	}
}