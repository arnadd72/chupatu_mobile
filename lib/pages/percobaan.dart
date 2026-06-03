import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SUV Indonesia Monitor',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const MyHomePage(title: 'SUV Indonesia'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() =>
      _MyHomePageState();
}

class _MyHomePageState
    extends State<MyHomePage> {

  final data = const [
    {
      "tgl": "Toyota Fortuner",
      "nilai": "Mesin: 2.8L Diesel | Status: Ready"
    },
    {
      "tgl": "Mitsubishi Pajero Sport",
      "nilai": "Mesin: 2.4L Diesel | Fuel: 75%"
    },
    {
      "tgl": "Honda CR-V",
      "nilai": "Mesin: 1.5 Turbo | Engine: Normal"
    },
    {
      "tgl": "Hyundai Creta",
      "nilai": "Mesin: 1.5L | Status: Active"
    },
    {
      "tgl": "Wuling Almaz",
      "nilai": "Turbo: Active | Fuel: 68%"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 25,
            vertical: 10,
          ),
          child: Column(
            children: [

              Container(
                padding:
                const EdgeInsets.symmetric(
                    vertical: 16),
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
                  children: [

                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: const [

                        Text(
                          "SUV Active",
                          style: TextStyle(
                            color:
                            Color(0xFF7367F0),
                            fontSize: 28,
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),

                        Text(
                          "2311102074 - Arvan Murbiyanto",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                            FontWeight.w500,
                            color:
                            Color(0xFF4B4B4B),
                          ),
                        ),
                      ],
                    ),

                    const CircleAvatar(
                      radius: 22,
                      backgroundColor:
                      Colors.grey,
                      child: Icon(
                        Icons.directions_car,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                margin:
                const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 35,
                ),
                decoration: BoxDecoration(
                  gradient:
                  const LinearGradient(
                    colors: [
                      Color(0xFF4839EB),
                      Color(0xFF7367F0),
                    ],
                  ),
                  borderRadius:
                  BorderRadius.circular(
                      10),
                ),
                child: Column(
                  children: [

                    const SizedBox(
                        height: 20),

                    const Text(
                      'SUV Overall Status',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(
                        height: 10),

                    const Text(
                      "EXCELLENT",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                        height: 20),

                    Padding(
                      padding:
                      const EdgeInsets
                          .symmetric(
                          horizontal:
                          15),
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                        children: const [

                          Text(
                            'Fuel\n80%',
                            style: TextStyle(
                              color:
                              Colors.white,
                              fontSize: 16,
                            ),
                          ),

                          Text(
                            'Engine\nNormal',
                            style: TextStyle(
                              color:
                              Colors.white,
                              fontSize: 16,
                            ),
                          ),

                          Text(
                            'GPS\nActive',
                            style: TextStyle(
                              color:
                              Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                        height: 20),
                  ],
                ),
              ),

              const Text(
                'SUV Indonesia Logs',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 28,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),

              Expanded(
                child: ListView.builder(
                  itemCount: data.length,
                  itemBuilder:
                      (context, index) {

                    return Column(
                      children: [

                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment
                              .spaceEvenly,
                          children: [

                            const Text(
                              'Mobil:\nStatus:',
                              style: TextStyle(
                                color:
                                Colors.blue,
                                fontSize: 18,
                              ),
                            ),

                            Text(
                              (data[index]
                              ["tgl"] ??
                                  "") +
                                  '\n' +
                                  (data[index]
                                  ["nilai"] ??
                                      ""),
                              style:
                              const TextStyle(
                                color:
                                Colors.blue,
                                fontSize: 18,
                                fontWeight:
                                FontWeight
                                    .w500,
                              ),
                              textAlign:
                              TextAlign.right,
                            ),
                          ],
                        ),

                        const SizedBox(
                            height: 15),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}