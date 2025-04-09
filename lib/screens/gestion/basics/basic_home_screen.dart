import 'package:bbd_limited/components/basic/card.dart';
import 'package:bbd_limited/components/basic/card_list.dart';
import 'package:bbd_limited/components/basic/report/report_card.dart';
import 'package:bbd_limited/components/basic/report/report_card_list.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:flutter/material.dart';
import '../../../models/user.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = await _authService.getUserInfo();
    if (mounted) {
      setState(() {
        _user = user;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                          backgroundImage:
                              const AssetImage(
                                    'assets/images/profile-picture.avif',
                                  )
                                  as ImageProvider,
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
                              'Bienvenue',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -1,
                              ),
                            ),
                            Text(
                              _user?.firstName ??
                                  _user?.username ??
                                  'Utilisateur',
                              style: TextStyle(letterSpacing: 0, fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Statistique",
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
                        children:
                            reportCardDataList.map((data) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3.0,
                                ),
                                child: ReportCard(
                                  icon: data.icon,
                                  title: data.title,
                                  quantity: data.quantity,
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              SliverToBoxAdapter(child: const SizedBox(height: 20)),

              SliverToBoxAdapter(
                child: Text(
                  "Informations de base",
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
                  crossAxisCount: 2, // Nombre de colonnes
                  mainAxisSpacing: 10, // Espacement vertical
                  crossAxisSpacing: 10, // Espacement horizontal
                  children:
                      cardDataList.map((data) {
                        return CustomCard(
                          icon: data.icon,
                          title: data.title,
                          description:
                              data.description, // Ajoutez vos données ici
                          backgroundColor:
                              data.backgroundColor, // Couleur de fond
                          iconColor: data.iconColor, // Couleur des icônes
                          titleColor: data.titleColor, // Couleur du titre
                          descriptionColor:
                              data.descriptionColor, // Couleur de la description
                          onPressed: data.onPressed,
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
