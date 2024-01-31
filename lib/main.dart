import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      name: 'home',
      path: '/',
      builder: (context, state) => MyHomePage(),
    ),
    GoRoute(
      name: 'view',
      path: '/viewAll',
      builder: (context, state) => lastPage(),
    ),
  ],
);

List<Map<String, dynamic>> _data = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('dataPenduduk');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

Future<List<Map<String, dynamic>>> fetchProvinces() async {
  final reponse = await rootBundle.loadString('assets/provinces.json');
  final List<dynamic> response = jsonDecode(reponse);
  return response
      .map<Map<String, dynamic>>((item) => {
            'name': item['name'],
            'id': item['id'],
          })
      .toList();
}

Future<List<Map<String, dynamic>>> fetchRegencies() async {
  final reponse = await rootBundle.loadString('assets/regencies.json');
  final List<dynamic> response = jsonDecode(reponse);
  final List<Map<String, dynamic>> mapedResponse = response
      .map<Map<String, dynamic>>((item) => {
            'name': item['name'],
            'provinceId': item['province_id'],
          })
      .toList();
  return mapedResponse;
}

final _dataPenduduk = Hive.box('dataPenduduk');

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Box<Map<String, dynamic>> hiveBox;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _ttlController = TextEditingController();
  String? _selectedProvince;
  String? _selectedProvinceId;
  String? _selectedDistrict;
  TextEditingController _pekerjaanController = TextEditingController();
  TextEditingController _pendidikanController = TextEditingController();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    final data = _dataPenduduk.keys.map((key) {
      final item = _dataPenduduk.get(key);
      return {
        'key': key,
        'name': item['name'],
        'ttl': item['ttl'],
        'selectedProvince': item['provinsi'],
        'selectedDistrict': item['kabupaten'],
        'pekerjaan': item['pekerjaan'],
        'pendidikan': item['pendidikan'],
      };
    }).toList();

    setState(() {
      _data = data.reversed.toList();
    });
  }

  Future<void> _createData(Map<String, String> newData) async {
    await _dataPenduduk.add(newData);
    _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
              child: TextFormField(
                controller: _nameController,
                validator: (String? value) {
                  if (value!.isEmpty) {
                    return 'Nama harus diisi';
                  }
                },
                decoration: InputDecoration(
                    border: OutlineInputBorder(), labelText: 'Nama'),
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
              child: TextFormField(
                controller: _ttlController,
                validator: (String? value) {
                  if (value!.isEmpty) {
                    return 'Tempat Tanggal Lahir harus diisi';
                  }
                },
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Tempat Tanggal Lahir'),
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchProvinces(),
                  builder: (BuildContext context,
                      AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator(); // Return a loading indicator while waiting for data.
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Text(
                          'No data available'); // Return a message when there is no data.
                    } else {
                      return DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Masukkan Provinsi'),
                        value: _selectedProvince,
                        onChanged: (value) {
                          setState(() {
                            _selectedProvince = value;
                            _selectedProvinceId = snapshot.data!.firstWhere(
                              (province) => province['name'] == value,
                            )['id'];
                          });
                        },
                        items: snapshot.data!.map<DropdownMenuItem<String>>(
                            (Map<String, dynamic> value) {
                          return DropdownMenuItem<String>(
                              value: value['name'], child: Text(value['name']));
                        }).toList(),
                        validator: (value) {
                          if (value == null) {
                            return 'Provinsi harus diisi';
                          } else {
                            return null;
                          }
                        },
                      );
                    }
                  }),
            ),
            Container(
              margin: EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchRegencies(),
                  builder: (BuildContext context,
                      AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator(); // Return a loading indicator while waiting for data.
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Text(
                          'No data available'); // Return a message when there is no data.
                    } else {
                      final regencies = snapshot.data!
                          .where((regency) =>
                              regency['provinceId'] == _selectedProvinceId)
                          .map<String>((regency) => regency['name'])
                          .toList();
                      return DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Masukkan Kabupaten'),
                        value: _selectedDistrict,
                        onChanged: (value) {
                          setState(() {
                            _selectedDistrict = value!;
                          });
                        },
                        items: regencies
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        validator: (value) {
                          if (value == null) {
                            return 'Kabupaten harus diisi';
                          } else {
                            return null;
                          }
                        },
                      );
                    }
                  }),
            ),
            Container(
              margin: EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
              child: TextFormField(
                controller: _pekerjaanController,
                validator: (String? value) {
                  if (value!.isEmpty) {
                    return 'Pekerjaan harus diisi';
                  }
                },
                decoration: InputDecoration(
                    border: OutlineInputBorder(), labelText: 'Pekerjaan'),
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
              child: TextFormField(
                controller: _pendidikanController,
                validator: (String? value) {
                  if (value!.isEmpty) {
                    return 'Pendidikan harus diisi';
                  }
                },
                decoration: InputDecoration(
                    border: OutlineInputBorder(), labelText: 'Pendidikan'),
              ),
            ),
            ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _createData({
                      'name': _nameController.text,
                      'ttl': _ttlController.text,
                      'selectedProvince': _selectedProvince ?? '',
                      'selectedDistrict': _selectedDistrict ?? '',
                      'pekerjaan': _pekerjaanController.text,
                      'pendidikan': _pendidikanController.text,
                    });
                      context.goNamed('view');
                  }
                },
                child: Text('Submit'))
          ],
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class lastPage extends StatefulWidget {
  @override
  State<lastPage> createState() => _lastPageState();
}

class _lastPageState extends State<lastPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: _data.length,
        itemBuilder: (_, index) {
          final currentItem = _data[index];
          return Card(
            child: ListTile(
              title: Text(currentItem['name']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  detailEdit(Key: currentItem['key'])));
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () =>
                        _dialogBuilder(context, currentItem['key']),
                    // Add your onPressed logic for the second button
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _dialogBuilder(BuildContext context, int key) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus Data'),
          content: const Text(
            'Yakin Hapus?',
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Yakin'),
              onPressed: () {
                _deleteItem(key);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => lastPage()));
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Tidak'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteItem(index) {
    final _dataPenduduk = Hive.box('dataPenduduk');
    _dataPenduduk.deleteAt(index);
    _refreshData();
  }

  void _refreshData() {
    final data = _dataPenduduk.keys.map((key) {
      final item = _dataPenduduk.get(key);
      return {
        'key': key,
        'name': item['name'],
        'ttl': item['ttl'],
        'selectedProvince': item['provinsi'],
        'selectedDistrict': item['kabupaten'],
        'pekerjaan': item['pekerjaan'],
        'pendidikan': item['pendidikan'],
      };
    }).toList();

    setState(() {
      _data = data.reversed.toList();
    });
  }
}

class detailEdit extends StatefulWidget {
  final int Key;
  detailEdit({required this.Key});

  @override
  State<detailEdit> createState() => _detailEditState();
}

class _detailEditState extends State<detailEdit> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _ttlController = TextEditingController();
  String? _selectedProvince;
  String? _selectedProvinceId;
  String? _selectedDistrict;
  TextEditingController _pekerjaanController = TextEditingController();
  TextEditingController _pendidikanController = TextEditingController();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
              child: TextFormField(
                controller: _nameController,
                validator: (String? value) {
                  if (value!.isEmpty) {
                    return 'Nama harus diisi';
                  }
                },
                decoration: InputDecoration(
                    border: OutlineInputBorder(), labelText: 'Nama'),
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
              child: TextFormField(
                controller: _ttlController,
                validator: (String? value) {
                  if (value!.isEmpty) {
                    return 'Tempat Tanggal Lahir harus diisi';
                  }
                },
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Tempat Tanggal Lahir'),
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchProvinces(),
                  builder: (BuildContext context,
                      AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Text('No data available');
                    } else {
                      return DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Masukkan Provinsi'),
                        value: _selectedProvince,
                        onChanged: (value) {
                          setState(() {
                            _selectedProvince = value;
                            _selectedProvinceId = snapshot.data!.firstWhere(
                              (province) => province['name'] == value,
                            )['id'];
                          });
                        },
                        items: snapshot.data!.map<DropdownMenuItem<String>>(
                            (Map<String, dynamic> value) {
                          return DropdownMenuItem<String>(
                              value: value['name'], child: Text(value['name']));
                        }).toList(),
                        validator: (value) {
                          if (value == null) {
                            return 'Provinsi harus diisi';
                          } else {
                            return null;
                          }
                        },
                      );
                    }
                  }),
            ),
            Container(
              margin: EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchRegencies(),
                  builder: (BuildContext context,
                      AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Text('No data available');
                    } else {
                      final regencies = snapshot.data!
                          .where((regency) =>
                              regency['provinceId'] == _selectedProvinceId)
                          .map<String>((regency) => regency['name'])
                          .toList();
                      return DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Masukkan Kabupaten'),
                        value: _selectedDistrict,
                        onChanged: (value) {
                          setState(() {
                            _selectedDistrict = value!;
                          });
                        },
                        items: regencies
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        validator: (value) {
                          if (value == null) {
                            return 'Kabupaten harus diisi';
                          } else {
                            return null;
                          }
                        },
                      );
                    }
                  }),
            ),
            Container(
              margin: EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
              child: TextFormField(
                controller: _pekerjaanController,
                validator: (String? value) {
                  if (value!.isEmpty) {
                    return 'Pekerjaan harus diisi';
                  }
                },
                decoration: InputDecoration(
                    border: OutlineInputBorder(), labelText: 'Pekerjaan'),
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
              child: TextFormField(
                controller: _pendidikanController,
                validator: (String? value) {
                  if (value!.isEmpty) {
                    return 'Pendidikan harus diisi';
                  }
                },
                decoration: InputDecoration(
                    border: OutlineInputBorder(), labelText: 'Pendidikan'),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Add your logic for submitting the edited data
                // For example, you can save it back to Hive or perform any other desired action
              },
              child: Text('Edit'),
            ),
          ],
        ),
      ),
    );
  }
}
