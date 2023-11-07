import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:paged_datatable/paged_datatable.dart';
import 'package:paged_datatable_example/post.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await initializeDateFormatting("en");

  PostsRepository.generate(200);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        PagedDataTableLocalization.delegate
      ],
      supportedLocales: const [Locale("es"), Locale("en")],
      locale: const Locale("en"),
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          colorScheme: const ColorScheme.light(primary: Colors.deepPurple, secondary: Colors.teal),
          textTheme: GoogleFonts.robotoTextTheme(),
          cardTheme: CardTheme(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          popupMenuTheme: PopupMenuThemeData(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)))),
      home: const MainView(),
    );
  }
}

class MainView extends StatefulWidget {
  const MainView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MainViewState();
}

const kCustomPagedDataTableTheme = PagedDataTableThemeData(
    rowColors: [
      Color(0xFFC4E6E3),
      Color(0xFFE5EFEE),
    ],
    backgroundColor: Color(0xFFE0F2F1),
    headerBackgroundColor: Color(0xFF80CBC4),
    filtersHeaderBackgroundColor: Color(0xFF80CBC4),
    footerBackgroundColor: Color(0xFF80CBC4),
    footerTextStyle: TextStyle(color: Colors.white),
    textStyle: TextStyle(fontWeight: FontWeight.normal),
    buttonsColor: Colors.white,
    chipTheme: ChipThemeData(
        backgroundColor: Colors.teal,
        labelStyle: TextStyle(color: Colors.white),
        deleteIconColor: Colors.white),
    configuration: PagedDataTableConfiguration(
        footer: PagedDataTableFooterConfiguration(footerVisible: true),
        allowRefresh: true,
        pageSizes: [50, 75, 100],
        initialPageSize: 50));

class _MainViewState extends State<MainView> {
  final tableController = PagedDataTableController<String, int, Post>();
  PagedDataTableThemeData? theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 208, 208, 208),
      padding: const EdgeInsets.all(20.0),
      child: PagedDataTable<String, int, Post>(
        rowsSelectable: true,
        theme: theme,
        idGetter: (post) => post.id,
        controller: tableController,
        fetchPage: (pageToken, pageSize, sortBy, filtering) async {
          if (filtering.valueOrNull("authorName") == "error!") {
            throw Exception("This is an unexpected error, wow!");
          }

          var result = await PostsRepository.getPosts(
              pageSize: pageSize,
              pageToken: pageToken,
              sortBy: sortBy?.columnId,
              sortDescending: sortBy?.descending ?? false,
              gender: filtering.valueOrNullAs<Gender>("gender"),
              authorName: filtering.valueOrNullAs<String>("authorName"),
              between: filtering.valueOrNullAs<DateTimeRange>("betweenDate"));
          return PaginationResult.items(
              elements: result.items, nextPageToken: result.nextPageToken);
        },
        initialPage: "",
        columns: [
          TableColumn(
            title: "Identificator",
            cellBuilder: (item) => Text(item.id.toString()),
            sizeFactor: .05,
          ),
          TableColumn(title: "Author", fixedSize: 200, cellBuilder: (item) => Text(item.author)),
          LargeTextTableColumn(
              title: "Content",
              fixedSize: 500,
              getter: (post) => post.content,
              setter: (post, newContent, rowIndex) async {
                await Future.delayed(const Duration(seconds: 1));
                post.content = newContent;
                return true;
              },
              sizeFactor: .3),
          TableColumn(
              id: "createdAt",
              title: "Created At",
              fixedSize: 200,
              sortable: true,
              cellBuilder: (item) => Text(DateFormat.yMd().format(item.createdAt))),
          DropdownTableColumn<Post, Gender>(
            title: "Gender",
            fixedSize: 200,
            getter: (post) => post.authorGender,
            setter: (post, newGender, rowIndex) async {
              post.authorGender = newGender;
              await Future.delayed(const Duration(seconds: 1));
              return true;
            },
            items: const [
              DropdownMenuItem(value: Gender.male, child: Text("Male")),
              DropdownMenuItem(value: Gender.female, child: Text("Female")),
              DropdownMenuItem(value: Gender.unespecified, child: Text("Unspecified")),
            ],
          ),
          TableColumn(
              title: "Enabled",
              fixedSize: 200,
              sizeFactor: null,
              cellBuilder: (item) => Text(item.isEnabled ? "Yes" : "No")),
          TextTableColumn(
              title: "Number",
              fixedSize: 200,
              id: "number",
              sortable: true,
              sizeFactor: .05,
              isNumeric: true,
              getter: (post) => post.number.toString(),
              setter: (post, newValue, rowIndex) async {
                await Future.delayed(const Duration(seconds: 1));

                int? number = int.tryParse(newValue);
                if (number == null) {
                  return false;
                }

                post.number = number;

                // if you want to do this too, dont forget to call refreshRow
                post.author = "empty content haha";
                tableController.refreshRow(rowIndex);
                return true;
              }),
          TableColumn(
              title: "Fixed Value",
              fixedSize: 200,
              cellBuilder: (item) => const Text("abc"),
              sizeFactor: .3),
        ],
        filters: [
          TextTableFilter(
              id: "authorName", title: "Author's name", chipFormatter: (text) => "By $text"),
          DropdownTableFilter<Gender>(
              id: "gender",
              title: "Gender",
              defaultValue: Gender.male,
              chipFormatter: (gender) => 'Only ${gender.name.toLowerCase()} posts',
              items: const [
                DropdownMenuItem(value: Gender.male, child: Text("Male")),
                DropdownMenuItem(value: Gender.female, child: Text("Female")),
                DropdownMenuItem(value: Gender.unespecified, child: Text("Unspecified")),
              ]),
          DatePickerTableFilter(
            id: "date",
            title: "Date",
            chipFormatter: (date) => 'Only on ${DateFormat.yMd().format(date)}',
            firstDate: DateTime(2000, 1, 1),
            lastDate: DateTime.now(),
          ),
          DateRangePickerTableFilter(
            id: "betweenDate",
            title: "Between",
            chipFormatter: (date) =>
                'Between ${DateFormat.yMd().format(date.start)} and ${DateFormat.yMd().format(date.end)}',
            firstDate: DateTime(2000, 1, 1),
            lastDate: DateTime.now(),
          )
        ],
        footer: TextButton(
          onPressed: () {},
          child: const Text("Im a footer button"),
        ),
        menu: PagedDataTableFilterBarMenu(items: [
          FilterMenuItem(
            title: const Text("Apply new theme"),
            onTap: () {
              setState(() {
                if (theme == null) {
                  theme = kCustomPagedDataTableTheme;
                } else {
                  theme = null;
                }
              });
            },
          ),
          const FilterMenuDivider(),
          FilterMenuItem(
            title: const Text("Remove row"),
            onTap: () {
              tableController.removeRow(tableController.currentDataset.first.id);
            },
          ),
          FilterMenuItem(
            title: const Text("Remove filters"),
            onTap: () {
              tableController.removeFilters();
            },
          ),
          FilterMenuItem(
              title: const Text("Add filter"),
              onTap: () {
                tableController.setFilter("gender", Gender.male);
              }),
          const FilterMenuDivider(),
          FilterMenuItem(
              title: const Text("Print selected rows"),
              onTap: () {
                var selectedPosts = tableController.getSelectedRows();
                debugPrint("SELECTED ROWS ----------------------------");
                debugPrint(selectedPosts
                    .map((e) => "Id [${e.id}] Author [${e.author}] Gender [${e.authorGender.name}]")
                    .join("\n"));
                debugPrint("------------------------------------------");
              }),
          FilterMenuItem(
              title: const Text("Unselect all rows"),
              onTap: () {
                tableController.unselectAllRows();
              }),
          FilterMenuItem(
              title: const Text("Select random row"),
              onTap: () {
                final random = Random.secure();
                tableController.selectRow(tableController
                    .currentDataset[random.nextInt(tableController.currentDataset.length)].id);
              }),
          const FilterMenuDivider(),
          FilterMenuItem(
              title: const Text("Update first row's gender and number"),
              onTap: () {
                tableController.modifyRowValue(1, (item) {
                  item.authorGender = Gender.male;
                  item.number = 1;
                  item.author = "Tomas";
                  item.content = "empty content";
                });
              }),
          const FilterMenuDivider(),
          FilterMenuItem(
            title: const Text("Refresh cache"),
            onTap: () {
              tableController.refresh(currentDataset: false);
            },
          ),
          FilterMenuItem(
            title: const Text("Refresh current dataset"),
            onTap: () {
              tableController.refresh();
            },
          ),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    tableController.dispose();
    super.dispose();
  }
}
