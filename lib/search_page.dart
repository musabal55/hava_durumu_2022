import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final sehirController =
      TextEditingController(); //textField içine yazılan değeri burada tutucaz



  //AlertDialog fonksiyonu
  void _showDialog(){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: new Text("Uyarı"),
          content: new Text("Şehir bulunamadı"),
          actions: [
            new FlatButton(onPressed: (){Navigator.of(context).pop();}, child: Text("Tamam"))
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          image: DecorationImage(
              fit: BoxFit.cover, image: AssetImage("assets/search.jpg"))),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor:
              Colors.transparent, //resmin backgroundu kaplaması için
          elevation: 0, // resmin backgroundu kaplaması için
        ),
        backgroundColor:
            Colors.transparent, //text in resmi örtmesini engelledik
        body: Center(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50.0),
                child: TextField(
                  controller:
                      sehirController, //sehirController.text ile erişicez
                  decoration: InputDecoration(hintText: "Şehir seçiniz"),
                  style: TextStyle(fontSize: 30),
                  textAlign: TextAlign.center,
                ),
              ),
              FlatButton(
                  onPressed: () async {
                    print(sehirController.text.length);
                    print(sehirController.text.trim().length);

                    // şehir arama boş id dönerse kontrol
                    var url = Uri.parse(
                        "https://www.metaweather.com/api/location/search/?query=${sehirController.text}");
                    var response = await http.get(url);
                    jsonDecode(response.body).isEmpty?
                    _showDialog()//uyarı fonksiyonunu çalıştır
                        :
                    Navigator.pop(context, sehirController.text.toUpperCase()); //text içindeki değeri home page aktarıyoruz
                  },
                  child: Text("Şehri Seç"))
            ],
          ),
        ),
      ),
    );
  }
}
