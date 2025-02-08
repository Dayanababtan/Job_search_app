import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('jobsBox');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Job Listings',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: JobListScreen(),
    );
  }
}

class JobListScreen extends StatefulWidget {
  @override
  _JobListScreenState createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  Box jobsBox = Hive.box('jobsBox');
  bool isOffline = false;

  @override
  void initState() {
    super.initState();
    checkConnectivity();
    if (jobsBox.get('jobs') == null) {
      fetchJobs();
    }
  }

  Future<void> checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      isOffline = connectivityResult == ConnectivityResult.none;
    });
  }

  Future<void> fetchJobs() async {
    checkConnectivity();
    if (isOffline) return;

    try {
      final response = await http.get(Uri.parse('http://localhost:2506/jobs'));
      if (response.statusCode == 200) {
        List jobs = json.decode(response.body);
        jobsBox.put('jobs', jobs); // Save to Hive
        setState(() {});
      }
    } catch (e) {
      setState(() {
        isOffline = true;
      });
    }
  }

  Future<void> addJob(Map<String, dynamic> job) async {
    await checkConnectivity();
    
    Box jobsBox = Hive.box('jobsBox');
    List jobs = jobsBox.get('jobs', defaultValue: []) ?? [];
    
    if (isOffline) {
      jobs.add(job);
      jobsBox.put('jobs', jobs);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Job added locally!')),
      );
    } else {
      try {
        final response = await http.post(
          Uri.parse('http://localhost:2506/job'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(job),
        );
        
        if (response.statusCode == 201) {
          jobs.add(json.decode(response.body)); // Add returned job data
          jobsBox.put('jobs', jobs);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Job added successfully!')),
          );
        } else {
          throw Exception('Failed to add job');
        }
      } catch (e) {
        jobs.add(job);
        jobsBox.put('jobs', jobs);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Job added locally due to network error!')),
        );
      }
    }
    setState(() {});
  }

  Future<void> deleteJob(int id) async {
    await checkConnectivity();
    if (isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must be online to delete a job!')),
      );
      return;
    }

    try {
      final response = await http.delete(Uri.parse('http://localhost:2506/job/$id'));
      if (response.statusCode == 200) {
        List jobs = jobsBox.get('jobs', defaultValue: []) ?? [];
        jobs.removeWhere((job) => job['id'] == id);
        jobsBox.put('jobs', jobs);
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Job deleted successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete job. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error connecting to server.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List jobs = jobsBox.get('jobs', defaultValue: []) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Job Listings'),
        actions: [
          // Refresh button to fetch jobs
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchJobs,
          ),
          // New button to open OpenJobsScreen
          IconButton(
            icon: Icon(Icons.work),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OpenJobsScreen()),
              );
            },
          ),
        ],
      ),
      body: jobs.isEmpty
          ? Center(
              child: isOffline
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('No internet connection!', style: TextStyle(color: Colors.red)),
                        ElevatedButton(
                          onPressed: fetchJobs,
                          child: Text('Retry'),
                        ),
                      ],
                    )
                  : CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                var job = jobs[index];
                return Card(
                  margin: EdgeInsets.all(10),
                  child: InkWell(
                    onTap: () {
                      // Navigate to JobDetailScreen when the job is tapped
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JobDetailScreen(job: job),
                        ),
                      );
                    },
                    child: ListTile(
                      title: Text('${job['id']}. ${job['title']}'),
                      subtitle: Text(job['company']),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteJob(job['id']),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final TextEditingController titleController = TextEditingController();
          final TextEditingController companyController = TextEditingController();
          final TextEditingController descriptionController = TextEditingController();
          final TextEditingController locationController = TextEditingController();
          final TextEditingController statusController = TextEditingController();
          final TextEditingController applicantsController = TextEditingController();
          
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Add Job'),
              content: Column(
                children: [
                  TextField(controller: titleController, decoration: InputDecoration(labelText: 'Title')),
                  TextField(controller: companyController, decoration: InputDecoration(labelText: 'Company')),
                  TextField(controller: descriptionController, decoration: InputDecoration(labelText: 'Description')),
                  TextField(controller: locationController, decoration: InputDecoration(labelText: 'Location')),
                  TextField(controller: statusController, decoration: InputDecoration(labelText: 'Status')),
                  TextField(controller: applicantsController, decoration: InputDecoration(labelText: 'Applicants')),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    addJob({
                      'id': DateTime.now().millisecondsSinceEpoch,
                      'title': titleController.text,
                      'company': companyController.text,
                      'description': descriptionController.text,
                      'location': locationController.text,
                      'status': statusController.text,
                      'applicants': applicantsController.text,
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

}

class JobDetailScreen extends StatelessWidget {
  final Map<String, dynamic> job;

  JobDetailScreen({required this.job});

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Job Listings'),
          
      
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Title: ${job['title']}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Company: ${job['company']}', style: TextStyle(fontSize: 18)),
          SizedBox(height: 8),
          Text('Description: ${job['description']}', style: TextStyle(fontSize: 16)),
          SizedBox(height: 8),
          Text('Location: ${job['location']}', style: TextStyle(fontSize: 16)),
          SizedBox(height: 8),
          Text('Status: ${job['status']}', style: TextStyle(fontSize: 16)),
          SizedBox(height: 8),
          Text('Applicants: ${job['applicants']}', style: TextStyle(fontSize: 16)),
          SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OpenJobsScreen()),
                );
              },
              child: Text('View Open Jobs'),
            ),
          ),
        ],
      ),
    ),
  );
}

}

class OpenJobsScreen extends StatelessWidget {
  final Box jobsBox = Hive.box('jobsBox');

  @override
  Widget build(BuildContext context) {
    List jobs = jobsBox.get('jobs', defaultValue: []) ?? [];
    List openJobs = jobs.where((job) => job['status'] == 'open').toList();

    return Scaffold(
      appBar: AppBar(title: Text('Open Jobs')),
      body: openJobs.isEmpty
          ? Center(child: Text('No open jobs available.'))
          : ListView.builder(
              itemCount: openJobs.length,
              itemBuilder: (context, index) {
                var job = openJobs[index];
                return Card(
                  margin: EdgeInsets.all(10),
                  child: ListTile(
                    title: Text('${job['id']}. ${job['title']}'),
                    subtitle: Text(job['company']),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Go back to delete jobs!')),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
