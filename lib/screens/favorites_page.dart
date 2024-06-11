import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:tobetoapp/bloc/favorites/favorite_bloc.dart';
import 'package:tobetoapp/bloc/favorites/favorite_event.dart';
import 'package:tobetoapp/bloc/favorites/favorite_state.dart';
import 'package:tobetoapp/models/lesson_model.dart';
import 'package:tobetoapp/repository/lessons/lesson_repository.dart';
import 'package:tobetoapp/screens/lesson_details_and_video/lesson_details_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    context.read<FavoritesBloc>().add(
        LoadFavorites()); // Uygulama baslatildiginda favorilere eklenmis dersin gosterilmesini sagliyoruz.
  }

  //BlocConsumer kullan!

  @override
  Widget build(BuildContext context) {
    final lessonRepository = context.read<LessonRepository>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Favorites'),
      ),
      body: BlocListener<FavoritesBloc, FavoritesState>(
        listener: (context, state) {
          if (state is FavoritesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.message}')),
            );
          }
        },
        child: BlocBuilder<FavoritesBloc, FavoritesState>(
          builder: (context, state) {
            if (state is FavoritesLoading) {
              return Center(child: CircularProgressIndicator());
            } else if (state is FavoritesLoaded) {
              final favoriteLessonIds = state.favoriteLessonIds;
              if (favoriteLessonIds.isEmpty) {
                return Center(child: Text('Henuz favorılere ders eklenmemistir!'));
              } else {
                return ListView.builder(
                  itemCount: favoriteLessonIds.length,
                  itemBuilder: (context, index) {
                    final lessonId = favoriteLessonIds[index];
               
                    return FutureBuilder<LessonModel>(
                      future: lessonRepository.getLessonById(lessonId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          print(
                              'Dersleri yuklerken hata olustu $lessonId: ${snapshot.error}');
                          return ListTile(
                            title: Text('Error: ${snapshot.error}'),
                          );
                        } else if (snapshot.hasData) {
                          final lesson = snapshot.data!;
                          return ListTile(
                            leading: lesson.image != null
                                ? Image.network(lesson.image!)
                                : null,
                            title: Text(lesson.title ?? 'No title'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(lesson.description ?? 'No description'),
                                Text(
                                  DateFormat('dd MMM yyyy, HH:mm')
                                      .format(lesson.startDate!),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      LessonDetailsPage(lesson: lesson),
                                ),
                              );
                            },
                          );
                        } else {
                          print('ID ait ders bulunamamistir: $lessonId');
                          return ListTile(
                            title: Text('Ders bulunamadi'),
                          );
                        }
                      },
                    );
                  },
                );
              }
            } else if (state is FavoritesError) {
              return Center(child: Text('Error: ${state.message}'));
            } else {
              return Center(child: Text('No favorites added'));
            }
          },
        ),
      ),
    );
  }
}