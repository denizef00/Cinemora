import 'package:flutter/material.dart';

class NewsView extends StatefulWidget {
  const NewsView({super.key});

  @override
  State<NewsView> createState() => _NewsViewState();
}

class _NewsViewState extends State<NewsView> {
  bool _firstisExpanded = false;
  bool _secondisExpanded = false;

  final int _firsttotalItem = 10;
  final int _secondtotalItem = 10;
  @override
  Widget build(BuildContext context) {
    final firstdisplayCount = _firstisExpanded
        ? _firsttotalItem
        : (_firsttotalItem < 3 ? _firsttotalItem : 3);
    final seconddisplayCount = _secondisExpanded
        ? _secondtotalItem
        : (_secondtotalItem < 3 ? _secondtotalItem : 3);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('    Upcoming TV Series'),
            SizedBox(height: 5),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.transparent,
              ),
              child: SizedBox(
                height: 100,
                child: Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: firstdisplayCount,
                      itemBuilder: (context, index) {
                        _upComingCard(
                          index,
                          context,
                          title: "Tv Series ${index + 1}",
                          upcomingDate: "11/07/2026",
                          color: Colors.red,
                        );
                      },
                    ),
                    SizedBox(height: 10),
                    if (_firsttotalItem > 3)
                      TextButton(
                        onPressed: () {
                          print("object");
                          setState(() {
                            _firstisExpanded = !_firstisExpanded;
                          });
                        },
                        child: Text(
                          _firstisExpanded ? "Show Less" : "Show More",
                        ),
                      ),
                  ],
                ),
              ),
            ),
            /*

            SizedBox(height: 200),
            Divider(height:1),
            Text('    Upcoming Movies'),
            SizedBox(height: 5),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.transparent,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                height: 100,
                child: Column(
                  children: [
                    ...List.generate(
                      seconddisplayCount,
                      (index) => _upComingCard(
                        index,
                        context,
                        title: "Movie ${index + 1}",
                        upcomingDate: "11/07/2026",
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: 5),
                    if (_secondtotalItem > 3)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _secondisExpanded = !_secondisExpanded;
                          });
                        },
                        child: Text(
                          _secondisExpanded ? "Show Less" : "Show More",
                        ),
                      ),
                  ],
                ),
              ),
            ),*/
          ],
        ),
      ),
    );
  }

  Container _upComingCard(
    int index,
    BuildContext context, {
    required String title,
    required String upcomingDate,
    required Color color,
  }) {
    return Container(
      height: 70,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                upcomingDate,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
