import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:hava_durumu/search_page.dart';
import 'package:geolocator/geolocator.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String sehir = "Ankara";
  int? sicaklik;
  var locationData;
  var woeid;
  String abbr = "c"; //arka plan resminin adını servisten cekecegiz
  Position? position;
  // 5 günlük hava tahminleri için listeye dolduruyoruz
  List temps = List.filled(5, 0, growable: true); // 5 elemanlı liste
  List abbrs = List.filled(5, 0, growable: true); // 5 elemanlı liste
  List dates = List.filled(5, 0, growable: true); // 5 elemanlı liste

  Future<void> getDevicePosition() async {
    try {
      position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low);
    } catch (error) {
      print("Konum çekilemedi");
    }
  }

  Future<void> getLocationData() async {
    var url = Uri.parse(
        "https://www.metaweather.com/api/location/search/?query=$sehir");
    locationData = await http.get(url);
    var locationDataParsed = jsonDecode(
        locationData.body); //jsonDecode : json içindeki tırnakları siler
    woeid = locationDataParsed[0]["woeid"];
    print("search woeid: $woeid");
  }

  Future<void> getLocationDataLatLong() async {
    var url = Uri.parse(
        "https://www.metaweather.com/api/location/search/?lattlong=${position!.latitude}, ${position!.longitude}");
    locationData = await http.get(url);
    var locationDataParsed = jsonDecode(utf8.decode(
        locationData.bodyBytes)); //jsonDecode : json içindeki tırnakları siler
    woeid = locationDataParsed[0]["woeid"];
    print("woeid:$woeid");
    sehir = locationDataParsed[0]["title"];
  }

  Future<void> getLocationTemperature() async {
    var url = Uri.parse("https://www.metaweather.com/api/location/$woeid/");
    var response = await http.get(url);
    var temperatureDataParsed = jsonDecode(response.body);

    setState(() {
      sicaklik =
          temperatureDataParsed["consolidated_weather"][0]["the_temp"].round();
      abbr = temperatureDataParsed["consolidated_weather"][0]
          ["weather_state_abbr"];

      //temps listesini dolduruyoruz
      for (int i = 0; i < temps.length; i++) {
        temps[i] = temperatureDataParsed["consolidated_weather"][i + 1]
                ["the_temp"]
            .round();

        abbrs[i] = temperatureDataParsed["consolidated_weather"][i + 1]
            ["weather_state_abbr"];

        dates[i] = temperatureDataParsed["consolidated_weather"][i + 1]
            ["applicable_date"];
      }
    });
  }

// fonksiyonları initState içinde asenkron çalıştırmak için yazdık
  void getDataFromApi() async {
    await getDevicePosition(); //cihazdan konum bilgisi çekiyoruz
    await getLocationDataLatLong(); // lat ve long cekiyoruz servisten
    getLocationTemperature(); // woeid bilgisi ile sıcaklık cektik
  }

  // sehir arama sayfasından dönuste kkullanıcaz
  void getDataFromAPIbyCity() async {
    await getLocationData(); // lat ve long cekiyoruz servisten
    getLocationTemperature(); // woeid bilgisi ile sıcaklık cektik
  }

  @override
  void initState() {
    getDevicePosition();
    getDataFromApi();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          image: DecorationImage(
              fit: BoxFit.cover, image: AssetImage("assets/$abbr.jpg"))),
      //sicaklik boş ise loading dolu ise scaffoldu boya
      child: sicaklik == null
          ? Center(child: CircularProgressIndicator())
          : Scaffold(
              backgroundColor:
                  Colors.transparent, //text in resmi örtmesini engelledik
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 60,
                      width: 60,
                      child: Image.network(
                          "https://www.metaweather.com/static/img/weather/png/$abbr.png"),
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    Text(
                      sicaklik.toString() + " C",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 70,
                          shadows: <Shadow>[
                            Shadow(
                                color: Colors.black,
                                blurRadius: 10,
                                offset: Offset(-5, 5))
                          ]),
                    ),
                    Container(
                      height: 40,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            flex:7,
                            child: Text(
                              sehir.toUpperCase(),
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  shadows: <Shadow>[
                                    Shadow(
                                        color: Colors.black,
                                        blurRadius: 10,
                                        offset: Offset(-3, 3))
                                  ]),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: IconButton(
                              onPressed: () async {
                                sehir = await Navigator.push(
                                    // searchPage den gelen şehir bilgisini await ile aldık
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => SearchPage()));
                                getDataFromAPIbyCity();
                                setState(() {
                                  sehir =
                                      sehir; // sehir verisi geldikten sonra ekranı tazele
                                });
                              },
                              icon: Icon(Icons.search),
                              iconSize: 32,
                            ),
                          )
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Container(child: buildDailyWeatherCards(context)),
                  ],
                ),
              ),
            ),
    );
  }

  Container buildDailyWeatherCards(BuildContext context) {
    List<Widget> cards =
        List.filled(5, widget, growable: false); // 5 elemanlı liste

    for (int i = 0; i < cards.length; i++) {
      cards[i] = DailyWeather(
          image: abbrs[i], temp: temps[i].toString(), date: dates[i]);
    }

    return Container(
      height: 100,
      // Container ekranın %90 sınırla
      width: MediaQuery.of(context).size.width * 0.9,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: cards,
      ),
    );
  }
}

class DailyWeather extends StatelessWidget {
  // servisten gelen verileri değişkene atıyoruz
  final String image;
  final String temp;
  final String date;

  // constructor atıyoruz
  const DailyWeather(
      {Key? key, required this.image, required this.temp, required this.date})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    //günleri yazdırmak için
    List <String> weekdays=["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"];
    String weekday = weekdays[DateTime.parse(date).weekday-1]; // servisten gelen tarihi parse et listeden haftanın gününü ver

    return Card(
      color: Colors.transparent,
      elevation: 2,
      child: Container(
        height: 120,
        width: 100,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Image.network(
            "https://www.metaweather.com/static/img/weather/png/$image.png",
            height: 50,
            width: 50,
          ),
          Text("$temp C"),
          Text(weekday),
        ]),
      ),
    );
  }
}
