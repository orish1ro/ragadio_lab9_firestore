
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentCrudPage extends StatefulWidget {
  const StudentCrudPage({super.key});

  @override
  State<StudentCrudPage> createState() => _StudentCrudPageState();
}

class _StudentCrudPageState extends State<StudentCrudPage> {
  final nameController = TextEditingController();
  final courseController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  String? editingId;
  bool isSaving = false;

  CollectionReference<Map<String, dynamic>> get students {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('students');
  }

  Future<void> saveStudent() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    final data = {
      'name': nameController.text.trim(),
      'course': courseController.text.trim(),
    };

    try {
      if (editingId == null) {
        await students.add(data);
      } else {
        await students.doc(editingId).update(data);
      }

      if (!mounted) return;

      nameController.clear();
      courseController.clear();

      setState(() {
        editingId = null;
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student record saved successfully!')),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() => isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Firestore error: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void editStudent(String id, Map<String, dynamic> data) {
    nameController.text = data['name'] ?? '';
    courseController.text = data['course'] ?? '';

    setState(() => editingId = id);
  }

  void cancelEdit() {
    nameController.clear();
    courseController.clear();

    setState(() => editingId = null);
  }

  Future<void> deleteStudent(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Are you sure you want to delete $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await students.doc(id).delete();

      if (!mounted) return;

      if (editingId == id) cancelEdit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student deleted successfully!')),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Firestore error: ${e.message}')),
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    courseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Records'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.school,
              size: 65,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            const Text(
              'Student Records Management',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        editingId == null
                            ? 'Add New Student'
                            : 'Update Student',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: nameController,
                        maxLength: 80,
                        decoration: const InputDecoration(
                          labelText: 'Student Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter student name.';
                          }
                          if (value.trim().length > 80) {
                            return 'Maximum of 80 characters.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: courseController,
                        maxLength: 80,
                        decoration: const InputDecoration(
                          labelText: 'Course',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.menu_book),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter course.';
                          }
                          if (value.trim().length > 80) {
                            return 'Maximum of 80 characters.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      ElevatedButton.icon(
                        onPressed: isSaving ? null : saveStudent,
                        icon: Icon(
                          editingId == null ? Icons.add : Icons.save,
                        ),
                        label: Text(
                          isSaving
                              ? 'Saving...'
                              : editingId == null
                                  ? 'Add Student'
                                  : 'Update Student',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(14),
                        ),
                      ),

                      if (editingId != null)
                        TextButton(
                          onPressed: cancelEdit,
                          child: const Text('Cancel Editing'),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Saved Student Records',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: students.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.green,
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No student records found. Add your first student!',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return Column(
                  children: docs.map((document) {
                    final data = document.data();
                    final name = data['name'] ?? '';
                    final course = data['course'] ?? '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(course),
                        trailing: Wrap(
                          spacing: 0,
                          children: [
                            IconButton(
                              tooltip: 'Edit student',
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.green,
                              ),
                              onPressed: () {
                                editStudent(
                                  document.id,
                                  data,
                                );
                              },
                            ),
                            IconButton(
                              tooltip: 'Delete student',
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                deleteStudent(
                                  document.id,
                                  name,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
