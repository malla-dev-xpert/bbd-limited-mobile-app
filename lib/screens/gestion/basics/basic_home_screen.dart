import 'package:bbd_limited/components/basic/card.dart';
import 'package:bbd_limited/components/basic/card_list.dart';
import 'package:bbd_limited/components/basic/report/report_card.dart';
import 'package:bbd_limited/components/basic/report/report_card_list.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:flutter/material.dart';
import '../../../models/user.dart';
import 'package:bbd_limited/core/services/container_services.dart';
import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  User? _user;
  final ContainerServices _containerServices = ContainerServices();
  int _expeditionsEnCours = 0;
  int _totalColisEnTransit = 0;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadExpeditionsStats();
  }

  Future<void> _loadUserInfo() async {
    final user = await _authService.getUserInfo();
    if (mounted) {
      setState(() {
        _user = user;
      });
    }
  }

  Future<void> _loadExpeditionsStats() async {
    setState(() {
      _expeditionsEnCours = 0;
      _totalColisEnTransit = 0;
    });
    try {
      final containers = await _containerServices.findAll(page: 0);
      final inProgressContainers =
          containers.where((c) => c.status == Status.INPROGRESS).toList();
      int totalPackages = 0;
      for (final container in inProgressContainers) {
        totalPackages += container.packages?.length ?? 0;
      }
      if (mounted) {
        setState(() {
          _expeditionsEnCours = inProgressContainers.length;
          _totalColisEnTransit = totalPackages;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _expeditionsEnCours = 0;
          _totalColisEnTransit = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isTablet = width > 800;
    final List<ReportCardData> dynamicReportCardDataList = [
      ReportCardData(
        title: AppLocalizations.of(context)
            .translate('home_expeditions_in_progress'),
        value: _expeditionsEnCours.toString(),
        backgroundColor: Colors.blue[800]!,
        textColor: Colors.white,
        icon: Icons.local_shipping,
      ),
      ReportCardData(
        title:
            AppLocalizations.of(context).translate('home_packages_in_transit'),
        value: _totalColisEnTransit.toString(),
        backgroundColor: Colors.orange[800]!,
        textColor: Colors.white,
        icon: Icons.inventory_2_rounded,
      ),
    ];
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      spacing: 10,
                      children: [
                        //display user profile picture
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: const AssetImage(
                            'assets/images/profile-picture.avif',
                          ) as ImageProvider,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF1A1E49),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)
                                  .translate('home_welcome'),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -1,
                              ),
                            ),
                            Text(
                              _user?.firstName ??
                                  _user?.username ??
                                  AppLocalizations.of(context)
                                      .translate('home_user'),
                              style: const TextStyle(
                                  letterSpacing: 0, fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppLocalizations.of(context).translate('home_statistics'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: dynamicReportCardDataList.map((data) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 3.0,
                            ),
                            child: ReportCard(
                              title: data.title,
                              value: data.value,
                              backgroundColor: data.backgroundColor,
                              textColor: data.textColor,
                              icon: data.icon,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: Text(
                  AppLocalizations.of(context).translate('home_basic_info'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10.0,
                  horizontal: 0,
                ),
                sliver: SliverGrid.count(
                  crossAxisCount: isTablet ? 3 : 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: getCardDataList(context).map((data) {
                    return CustomCard(
                      icon: data.icon,
                      title: data.title,
                      backgroundColor: data.backgroundColor,
                      iconColor: data.iconColor,
                      titleColor: data.titleColor,
                      onPressed: data.onPressed,
                      isTablet: isTablet,
                      description: data.description,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
