import 'dart:async';

import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/services/location_service.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_bloc.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_events.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_states.dart';
import 'package:client/modules/job_order/presentation/widgets/booking_dialog_sheet.dart';
import 'package:client/modules/store_items/presentation/bloc/store_items_bloc.dart';
import 'package:client/modules/store_items/presentation/bloc/store_items_events.dart';
import 'package:client/modules/store_items/presentation/bloc/store_items_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class JobOrderSummaryScreen extends StatefulWidget {
  static String routeName = "JobOrderSummaryScreen";
  static String route = "/JobOrderSummaryScreen/:id";
  const JobOrderSummaryScreen({super.key, required this.id});

  final String id;

  @override
  State<JobOrderSummaryScreen> createState() => _JobOrderSummaryScreenState();
}

class _JobOrderSummaryScreenState extends State<JobOrderSummaryScreen> {
  Stream<Position>? locationStream;
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  late final JobOrderBloc _joBloc;

  Future<void> init() async {
    locationStream = await dpLocator<LocationService>().getLocationStream();
  }

  @override
  void initState() {
    init();
    _joBloc = context.read<JobOrderBloc>();
    // Ensure summary can be opened from history/inbox (not only right after booking).
    Future.microtask(() {
      if (!mounted) return;
      _joBloc.add(LoadJOEvent(widget.id));
    });
    super.initState();
  }

  @override
  void dispose() {
    // Avoid looking up inherited widgets in dispose (can crash during route transitions).
    _joBloc.jobOrder = null;
    _joBloc.joServices.clear();
    _joBloc.assignedPersonel.clear();
    _joBloc.joServices.clear();
    _joBloc.selectedOptions.clear();
    super.dispose();
  }

  CameraPosition _nemo = const CameraPosition(
    target: LatLng(0, 0),
  );

  Future<void> _goToLoc([Position? currentPos]) async {
    final GoogleMapController controller = await _controller.future;
    var location =
        currentPos ?? await dpLocator<LocationService>().getLocation();
    var campost = CameraPosition(
        target: LatLng(location.latitude, location.longitude), zoom: 17);
    await controller.animateCamera(CameraUpdate.newCameraPosition(campost));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: BlocConsumer<JobOrderBloc, JOState>(
              listener: (context, state) {
                var bloc = BlocProvider.of<JobOrderBloc>(context);
                final merchantId = bloc.jobOrder?.merchantID;
                if (merchantId != null && merchantId.isNotEmpty) {
                  BlocProvider.of<StoreItemsBloc>(context)
                      .add(StoreItemLoadEvent(merchantId));
                }
                setState(() {
                  _nemo = CameraPosition(
                      target: LatLng(bloc.jobOrder?.latitude ?? 0,
                          bloc.jobOrder?.longitude ?? 0));
                });
              },
              builder: (context, state) {
                var bloc = BlocProvider.of<JobOrderBloc>(context);
                return StreamBuilder(
                    stream: locationStream,
                    builder: (context, state) {
                      return GoogleMap(
                        mapType: MapType.normal,
                        indoorViewEnabled: false,
                        myLocationButtonEnabled: true,
                        zoomControlsEnabled: false,
                        trafficEnabled: false,
                        initialCameraPosition: _nemo,
                        myLocationEnabled: false,
                        markers: {
                          Marker(
                              markerId: const MarkerId("serviceArea"),
                              position: LatLng(bloc.jobOrder?.latitude ?? 0,
                                  bloc.jobOrder?.longitude ?? 0))
                        },
                        onMapCreated: (GoogleMapController controller) {
                          if (!_controller.isCompleted) {
                            _controller.complete(controller);
                          }
                          Future.delayed(
                            const Duration(seconds: 1),
                            () {
                              var jo = bloc.jobOrder;
                              if (jo != null) {
                                _goToLoc(
                                  Position(
                                      longitude: jo.longitude,
                                      latitude: jo.latitude,
                                      timestamp: DateTime.now(),
                                      accuracy: 0,
                                      altitude: 0,
                                      altitudeAccuracy: 0,
                                      heading: 0,
                                      headingAccuracy: 0,
                                      speed: 0,
                                      speedAccuracy: 0),
                                );
                              } else {
                                _goToLoc(state.data);
                              }
                            },
                          );
                        },
                      );
                    });
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: BlocConsumer<StoreItemsBloc, StoreItemsState>(
              listener: (context, state) {
                // TODO: implement listener
              },
              builder: (context, state) {
                if (state is StoreItemLoadingState) {
                  return const BookingDialogSheet()
                      .animate(autoPlay: true)
                      .shimmer();
                }
                return const BookingDialogSheet();
              },
            ),
          ),
          Positioned(
            left: 0,
            top: 50,
            child: IconButton(
              onPressed: () {
                context.pop();
              },
              icon: Icon(
                Icons.chevron_left,
                size: 40,
                color: ColorPalette.primaryColorDark,
              ),
            ),
          )
        ],
      ),
    );
  }
}
