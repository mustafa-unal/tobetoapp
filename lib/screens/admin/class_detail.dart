import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tobetoapp/bloc/admin/admin_bloc.dart';
import 'package:tobetoapp/bloc/admin/admin_event.dart';
import 'package:tobetoapp/bloc/admin/admin_state.dart';

class ClassDetailsPage extends StatelessWidget {
  final String classId;

  const ClassDetailsPage({required this.classId, super.key});

  @override
  Widget build(BuildContext context) {
    context.read<AdminBloc>().add(LoadClassDetails(classId));

    return PopScope(
      onPopInvoked: (popped) {
        if (popped) {
          context.read<AdminBloc>().add(LoadClasses());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sınıf Detayları'),
        ),
        body: BlocBuilder<AdminBloc, AdminState>(
          builder: (context, state) {
            if (state is AdminLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ClassDetailsLoaded) {
              return DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'Kullanıcılar'),
                        Tab(text: 'Dersler'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          ListView.builder(
                            itemCount: state.users.length,
                            itemBuilder: (context, index) {
                              final user = state.users[index];
                              return Column(
                                children: [
                                  ListTile(
                                    title: Text(
                                        '${user.firstName} ${user.lastName}'),
                                    subtitle: Text('Email: ${user.email}'),
                                  ),
                                  const Divider(
                                    thickness: 1, // Çizginin kalınlığı
                                    color: Colors.grey, // Çizginin rengi
                                  ),
                                ],
                              );
                            },
                          ),
                          ListView.builder(
                            itemCount: state.lessons.length,
                            itemBuilder: (context, index) {
                              final lesson = state.lessons[index];
                              return Column(
                                children: [
                                  ListTile(
                                    title: Text(lesson.title!),
                                    subtitle: Text(
                                        'Açıklama: ${lesson.description}'),
                                  ),
                                  const Divider(
                                    thickness: 1, // Çizginin kalınlığı
                                    color: Colors.grey, // Çizginin rengi
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            } else if (state is AdminError) {
              return Center(
                  child:
                      Text('Sınıf detayları yüklenirken bir hata oluştu. Lütfen tekrar deneyiniz.'));
            } else {
              return const Center(child: Text('No class details found'));
            }
          },
        ),
      ),
    );
  }
}
