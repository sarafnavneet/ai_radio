// ignore: import_of_legacy_library_into_null_safe
import 'package:alan_voice/alan_voice.dart';
import 'package:audioplayers/audioplayers_api.dart';
import 'package:audioplayers/audioplayers.dart' show AudioPlayer;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velocity_x/velocity_x.dart';

import 'package:ai_radio/model/radio.dart';
import 'package:ai_radio/utils/ai_util.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<MyRadio> radios = [];
  late MyRadio _selectedRadio;
  Color _selectedColor = AIColor.primaryColor1;
  bool isPlaying = false;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    setupAlan();
    fetchRadios();

    _audioPlayer.onPlayerStateChanged.listen((event) {
      if (event == PlayerState.PLAYING)
        isPlaying = true;
      else
        isPlaying = false;
    });
    setState(() {});
  }

  setupAlan() {
    AlanVoice.addButton(
        "d720ca49966659a3ca0213af30bfedca2e956eca572e1d8b807a3e2338fdd0dc/stage",
        buttonAlign: AlanVoice.BUTTON_ALIGN_RIGHT);
    AlanVoice.callbacks.add((command) => handleCommand(command.data));
  }

  handleCommand(Map<String, dynamic> response) {
    switch (response["commmand"]) {
      case "play":
        _playMusic(_selectedRadio.url);
        break;
      case "channel_play":
        {
          _audioPlayer.pause();
          int index = response["id"];
          MyRadio newRadio = radios[index];
          radios.remove(newRadio);
          radios.insert(0, newRadio);
          _playMusic(newRadio.url);
        }
        break;
      case "stop/pause":
        _audioPlayer.stop();
        break;
      case "next":
        final index = _selectedRadio.id;
        int length = radios.length;
        MyRadio newRadio = radios[(index + 1) % length];
        radios.remove(newRadio);
        radios.insert(0, newRadio);
        _playMusic(newRadio.url);
        break;
      default:
        print("${response["command"]}");
        break;
    }
  }

  fetchRadios() async {
    final radioJson = await rootBundle.loadString("assets/radio.json");
    radios = MyRadioList.fromJson(radioJson).radios;
    print(radios);
    setState(() {});
  }

  _playMusic(String url) {
    _audioPlayer.play(url);
    _selectedRadio = radios.firstWhere((element) => url == url);
    print(_selectedRadio.name);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Container(
            color: _selectedColor,
            child: [
              100.heightBox,
              "All Channels".text.xl.white.semiBold.make(),
              20.heightBox,
              ListView(
                  padding: Vx.m0,
                  shrinkWrap: true,
                  children: radios
                      .map((e) => ListTile(
                          leading: CircleAvatar(
                            backgroundImage: (NetworkImage(e.icon)),
                          ),
                          title: "${e.name} FM".text.white.make(),
                          subtitle: e.tagline.text.white.make()))
                      .toList())
            ].vStack()),
      ),
      body: Stack(
        children: [
          VxAnimatedBox()
              .seconds(sec: 1)
              .size(context.screenWidth, context.screenHeight)
              .withGradient(LinearGradient(
                  colors: [AIColor.primaryColor2, _selectedColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight))
              .make(),
          AppBar(
            title: Text("AI Radio")
                .text
                .xl4
                .white
                .make()
                .shimmer(primaryColor: Vx.purple300, secondaryColor: Vx.white),
            backgroundColor: Colors.transparent,
            elevation: 0.0,
            centerTitle: true,
          ),
          radios.length != 0
              ? VxSwiper.builder(
                  itemCount: radios.length,
                  aspectRatio: 1.0,
                  enlargeCenterPage: true,
                  onPageChanged: (index) {
                    _selectedRadio = radios[index];
                    final color = radios[index].color;
                    _selectedColor = Color(int.parse(color));
                    setState(() {});
                  },
                  itemBuilder: (context, index) {
                    final rad = radios[index];
                    return VxBox(
                      child: ZStack([
                        Positioned(
                          top: 0.0,
                          right: 0.0,
                          child: VxBox(
                            child:
                                rad.category.text.uppercase.white.make().px16(),
                          )
                              .height(40)
                              .black
                              .alignCenter
                              .withRounded(value: 10.0)
                              .make(),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: VStack(
                            [
                              rad.name.text.xl3.white.bold.make(),
                              5.heightBox,
                              rad.tagline.text.sm.white.semiBold.make(),
                            ],
                            crossAlignment: CrossAxisAlignment.center,
                          ),
                        ),
                        Align(
                            alignment: Alignment.center,
                            child: [
                              Icon(CupertinoIcons.pause_circle,
                                  color: Colors.white),
                              10.heightBox,
                              "Double Tap to play".text.gray300.make()
                            ].vStack()),
                      ]),
                    )
                        .clip(Clip.antiAlias)
                        .bgImage(DecorationImage(
                            image: NetworkImage(rad.image),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                                Colors.black.withOpacity(0.3),
                                BlendMode.darken)))
                        .border(color: Colors.black, width: 5.0)
                        .withRounded(value: 60.0)
                        .make()
                        .onInkDoubleTap(() {
                      _playMusic(rad.url);
                    }).p16();
                  },
                ).centered()
              : Center(
                  child: CircularProgressIndicator(),
                ),
          30.heightBox,
          Align(
            alignment: Alignment.bottomCenter,
            child: [
              if (isPlaying)
                "Playing now - ${_selectedRadio.name} FM".text.makeCentered(),
              Icon(
                isPlaying == true
                    ? CupertinoIcons.stop_circle
                    : CupertinoIcons.play_circle,
                color: Colors.white,
                size: 50,
              ).onTap(() {
                if (isPlaying) {
                  _audioPlayer.stop();
                  isPlaying = false;
                } else
                  _playMusic(_selectedRadio.url);
                isPlaying = true;
              }),
            ].vStack(),
          ).pOnly(bottom: context.percentHeight * 12)
        ],
        fit: StackFit.expand,
      ),
    );
  }
}
