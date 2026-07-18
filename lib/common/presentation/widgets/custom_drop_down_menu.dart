import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:pinput/pinput.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/presentation/widgets/custom_text_field.dart';

class CustomDropDownMenu extends StatefulWidget {
  const CustomDropDownMenu({
    super.key,
    this.label = "Select",
    this.items = const [],
    this.onSelect,
    this.value,
    this.error,
    this.fieldKey,
    this.textFieldMode = false,
    this.controller,
    this.iconSize = 35,
    this.borderRadius = 12,
  });

  final String label;
  final double iconSize;
  final String? value;
  final String? error;
  final GlobalKey<FormFieldState>? fieldKey;
  final void Function(String? value)? onSelect;
  final List<({String name, String key})> items;
  final bool textFieldMode;
  final double borderRadius;
  final TextEditingController? controller;

  @override
  State<CustomDropDownMenu> createState() => _CustomDropDownMenuState();
}

class _CustomDropDownMenuState extends State<CustomDropDownMenu> {
  late TextEditingController searchController;

  @override
  void initState() {
    searchController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String? parseValue(String? val) {
    var items = widget.items.where((element) => element.name == val);
    if (items.isNotEmpty) {
      var item = items.first;
      return "${item.name}:${item.key}";
    } else {
      return val;
    }
  }

  String? parseName(String? val) {
    var items = widget.items.where((element) => element.name == val);
    if (items.length > 1) {
      var item = items.first;
      return "${item.name} (${item.key})";
    } else {
      return val;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.textFieldMode) {
      return textfieldDropdown();
    }

    return searchableDropdown();
  }

  TypeAheadField<String> textfieldDropdown() {
    return TypeAheadField<String>(
      key: widget.fieldKey,
      controller: widget.controller,
      builder: (context, controller, focusNode) {
        if (widget.value?.isNotEmpty ?? false) {
          controller.setText(widget.value!);
        }
        return CustomTextField(
          label: widget.label,
          focusNode: focusNode,
          borderRadius: widget.borderRadius,
          controller: controller,
          trailing: RotatedBox(
            quarterTurns: 1,
            child: Icon(
              Icons.chevron_right,
              color: ColorPalette.primaryColorDark,
            ),
          ),
        );
      },
      itemBuilder: (BuildContext context, String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              value,
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
      onSelected: (String value) {
        widget.controller?.text = value;
        widget.onSelect?.call(value);
      },
      emptyBuilder: (context) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    "${widget.controller?.text} will be added as new Category upon save.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ColorPalette.secondaryText,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      suggestionsCallback: (String search) {
        return widget.items
            .map((e) => e.name)
            .where((element) =>
                element.toLowerCase().contains(search.toLowerCase()))
            .toList();
      },
    );
  }

  DropdownButtonFormField2<String> searchableDropdown() {
    return DropdownButtonFormField2<String>(
      key: widget.fieldKey,
      isExpanded: true,
      value: parseValue(widget.value),
      enableFeedback: true,
      decoration: InputDecoration(
          labelText: widget.label,
          errorText: widget.error,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          contentPadding:
              const EdgeInsets.only(left: 10, right: 7, top: 12, bottom: 12)),
      items: (widget.items.map((item) {
        return DropdownMenuItem<String>(
          value: "${item.name}:${item.key}",
          child: Text(
            parseName(item.name) ?? item.name,
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList()),
      onChanged: (val) {
        var key = val?.split(":").last;
        var items = widget.items.where((element) => element.key == key);
        if (items.isNotEmpty) {
          var item = items.first;
          widget.onSelect?.call(item.name);
        }
      },
      dropdownSearchData: DropdownSearchData(
        searchController: searchController,
        searchInnerWidgetHeight: 50,
        searchInnerWidget: Container(
          height: 63,
          padding: const EdgeInsets.only(
            top: 8,
            right: 8,
            left: 8,
          ),
          child: CustomTextField(
            label: 'Search for ${widget.label}',
            borderRadius: widget.borderRadius,
            controller: searchController,
          ),
        ),
        searchMatchFn: (item, searchValue) {
          return item.value
              .toString()
              .toLowerCase()
              .contains(searchValue.toLowerCase());
        },
      ),
      iconStyleData: IconStyleData(
        iconSize: widget.iconSize,
        icon: RotatedBox(
          quarterTurns: 1,
          child: Icon(
            Icons.chevron_right,
            color: ColorPalette.primaryColorDark,
          ),
        ),
        openMenuIcon: RotatedBox(
          quarterTurns: 3,
          child: Icon(
            Icons.chevron_right,
            color: ColorPalette.primaryColorDark,
          ),
        ),
      ),
      dropdownStyleData: DropdownStyleData(
        useSafeArea: true,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}
