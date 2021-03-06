import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:mighty_news/AppLocalizations.dart';
import 'package:mighty_news/components/AppWidgets.dart';
import 'package:mighty_news/main.dart';
import 'package:mighty_news/network/RestApis.dart';
import 'package:mighty_news/screens/ChooseTopicScreen.dart';
import 'package:mighty_news/screens/HomeFragment.dart';
import 'package:mighty_news/screens/LoginScreen.dart';
import 'package:mighty_news/screens/NewsDetailScreen.dart';
import 'package:mighty_news/screens/ProfileFragment.dart';
import 'package:mighty_news/utils/Colors.dart';
import 'package:mighty_news/utils/Common.dart';
import 'package:mighty_news/utils/Constants.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:package_info/package_info.dart';

import 'CategoryFragment.dart';
import 'SearchNewsFragment.dart';
import 'SuggestedForYouFragment.dart';

class DashboardScreen extends StatefulWidget {
  static String tag = '/DashboardScreen';

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> with AfterLayoutMixin<DashboardScreen> {
  List<Widget> widgets = [];
  int currentIndex = 0;

  DateTime currentBackPressTime;

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    setDynamicStatusBarColor();

    widgets.add(HomeFragment());
    widgets.add(SuggestedForYouFragment());
    widgets.add(CategoryFragment());
    widgets.add(SearchNewsFragment());
    widgets.add(ProfileFragment());

    setState(() {});

    LiveStream().on(checkMyTopics, (v) {
      currentIndex = 0;
      setState(() {});
    });
    LiveStream().on(tokenStream, (v) {
      LoginScreen(isNewTask: false).launch(context);
    });

    await Future.delayed(Duration(milliseconds: 400));

    window.onPlatformBrightnessChanged = () {
      if (getIntAsync(THEME_MODE_INDEX) == ThemeModeSystem) {
        appStore.setDarkMode(MediaQuery.of(context).platformBrightness == Brightness.light);
      }
    };
  }

  @override
  void afterFirstLayout(BuildContext context) {
    appLocale = AppLocalizations.of(context);
    appStore.setLanguage(appStore.selectedLanguageCode, context: context);

    if (isMobile) {
      OneSignal.shared.setNotificationOpenedHandler((OSNotificationOpenedResult notification) async {
        String notId = await notification.notification.payload.additionalData["ID"];

        if (notId.validate().isNotEmpty) {
          String heroTag = '$notId${currentTimeStamp()}';

          NewsDetailScreen(id: notId.toString(), heroTag: heroTag).launch(context);
        }
      });
    }


  }

  @override
  void dispose() {
    super.dispose();
    LiveStream().dispose(checkMyTopics);
    LiveStream().dispose(tokenStream);

    window.onPlatformBrightnessChanged = null;
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WillPopScope(
        onWillPop: () async {
          DateTime now = DateTime.now();
          if (currentBackPressTime == null || now.difference(currentBackPressTime) > 2.seconds) {
            currentBackPressTime = now;
            toast(AppLocalizations.of(context).translate('exit_app'));
            return Future.value(false);
          }
          return Future.value(true);
        },
        child: Scaffold(
          body: Container(child: widgets[currentIndex]),
          bottomNavigationBar: Observer(
            builder: (_) => BottomNavigationBar(
              currentIndex: currentIndex,
              items: [
                BottomNavigationBarItem(
                  icon: Icon(AntDesign.home, color: context.theme.iconTheme.color),
                  label: 'Home',
                  activeIcon: Icon(AntDesign.home, color: colorPrimary),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined, color: context.theme.iconTheme.color),
                  label: 'Suggested For You',
                  activeIcon: Icon(Icons.dashboard_outlined, color: colorPrimary),
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: EdgeInsets.all(7),
               
                    color: Colors.green,
                    child: Text("LiveTV",style: TextStyle(color: Colors.white),)),
                  label: 'Live TV',
                  activeIcon: Container(
                    padding: EdgeInsets.all(7),
               
                    color: Colors.green,
                    child: Text("LiveTV",style: TextStyle(color: Colors.white),)),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Ionicons.ios_search, color: context.theme.iconTheme.color),
                  label: 'Search News',
                  activeIcon: Icon(Ionicons.ios_search, color: colorPrimary),
                ),
                BottomNavigationBarItem(
                  icon:
                      appStore.isLoggedIn ? cachedImage(appStore.userProfileImage, height: 24, width: 24, fit: BoxFit.cover).cornerRadiusWithClipRRect(15) : Icon(MaterialIcons.person_outline, color: context.theme.iconTheme.color),
                  label: 'Profile',
                  activeIcon: appStore.isLoggedIn
                      ? Container(
                          decoration: BoxDecoration(border: Border.all(color: colorPrimary), shape: BoxShape.circle),
                          child: cachedImage(
                            appStore.userProfileImage,
                            height: 24,
                            width: 24,
                            fit: BoxFit.cover,
                          ).cornerRadiusWithClipRRect(15))
                      : Icon(MaterialIcons.person_outline, color: colorPrimary),
                ),
              ],
              type: BottomNavigationBarType.fixed,
              showUnselectedLabels: false,
              showSelectedLabels: false,
              onTap: (i) async {
                if (i == 1) {
                  if (!appStore.isLoggedIn) {
                    LoginScreen().launch(context);
                  } else if (appStore.myTopics.isEmpty && i == 1) {
                    await ChooseTopicScreen().launch(context);

                    if (appStore.myTopics.isNotEmpty) {
                      currentIndex = 1;
                    }
                  } else {
                    currentIndex = i;
                  }
                } else {
                  currentIndex = i;
                }

                setState(() {});
              },
            ),
          ),
        ),
      ),
    );
  }
}
