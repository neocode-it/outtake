import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:outtake/bloc/gallery/gallerycubit_cubit.dart';
import 'package:outtake/bloc/selection/selection_cubit.dart';
import 'package:outtake/classes/gallery_image_file.dart';
import 'package:outtake/core/widgets/custom_image_viewer.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  @override
  void initState() {
    context.read<GalleryCubit>().loadGallery();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: BlocBuilder<GalleryCubit, GalleryState>(
        builder: (context, galleryState) {
          if (galleryState is GalleryLoaded) {
            return BlocBuilder<SelectionCubit, SelectionState>(
              builder: (context, selectionState) {
                final bool isSelectionActive =
                    selectionState is SelectionActive;
                return PopScope(
                  canPop: !isSelectionActive,
                  onPopInvokedWithResult: (didPop, result) {
                    if (didPop) return;
                    if (isSelectionActive) {
                      context.read<SelectionCubit>().cancalSelection();
                    }
                  },
                  child: _gallery(galleryState.gallery),
                );
              },
            );
          }
          
          if (galleryState is GalleryError) {
            return _errorView(galleryState.message);
          }
          
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }

  PreferredSize _appBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: BlocBuilder<SelectionCubit, SelectionState>(
        builder: (context, state) {
          if (state is SelectionActive) {
            return AppBar(
              title: Text("${state.indexes.length} Bilder ausgewählt"),
              actions: [
                IconButton(
                  onPressed: () async {
                    await context
                        .read<GalleryCubit>()
                        .deleteSelectedImages(state.indexes);
                    if (context.mounted) {
                      context.read<SelectionCubit>().cancalSelection();
                    }
                  },
                  icon: const Icon(Icons.delete),
                )
              ],
            );
          }
          return AppBar(
            title: const Text("Galerie"),
            actions: [
              IconButton(
                onPressed: () => _showCleanupOptions(context),
                icon: const Icon(Icons.cleaning_services_outlined),
                tooltip: 'Alte Bilder löschen',
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCleanupOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Speicherplatz freigeben",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.delete_sweep),
                title: const Text('Älter als 1 Woche löschen'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final count = await context
                      .read<GalleryCubit>()
                      .deleteImagesOlderThan(const Duration(days: 7));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$count Bilder gelöscht')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_sweep),
                title: const Text('Älter als 1 Monat löschen'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final count = await context
                      .read<GalleryCubit>()
                      .deleteImagesOlderThan(const Duration(days: 30));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$count Bilder gelöscht')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_sweep),
                title: const Text('Älter als 6 Monate löschen'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final count = await context
                      .read<GalleryCubit>()
                      .deleteImagesOlderThan(const Duration(days: 180));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$count Bilder gelöscht')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_sweep),
                title: const Text('Älter als 1 Jahr löschen'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final count = await context
                      .read<GalleryCubit>()
                      .deleteImagesOlderThan(const Duration(days: 365));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$count Bilder gelöscht')),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _gallery(Map<String, List<GalleryImageFile>> galleryItems) {
    final orientation = MediaQuery.of(context).orientation;
    final int crossAxisCount = orientation == Orientation.portrait ? 3 : 6;
    final allImages =
        galleryItems.values.expand((list) => list).toList();

    return ListView.builder(
      itemCount: galleryItems.length,
      itemBuilder: (context, index) {
        final date = galleryItems.keys.elementAt(index);
        final List<GalleryImageFile> images = galleryItems[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                date,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
              ),
              itemCount: images.length,
              itemBuilder: (context, index) {
                return _image(images[index], allImages);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _image(GalleryImageFile galleryFile, List<GalleryImageFile> allImages) {
    final index = galleryFile.id;
    final file = galleryFile.file;
    return GestureDetector(
      onLongPress: () {
        context.read<SelectionCubit>().toggleSelection(index);
      },
      onTap: () {
        if (context.read<SelectionCubit>().state is SelectionActive) {
          context.read<SelectionCubit>().toggleSelection(index);
        } else {
          final flatIndex =
              allImages.indexWhere((img) => img.id == galleryFile.id);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CustomImageViewer(
                imageProviders:
                    allImages.map((e) => FileImage(e.file)).toList(),
                initialIndex: flatIndex >= 0 ? flatIndex : 0,
              ),
            ),
          );
        }
      },
      child: BlocBuilder<SelectionCubit, SelectionState>(
        buildWhen: (previous, current) {
          if (previous.indexes.contains(index) &&
              current.indexes.contains(index)) {
            return false;
          } else if (!previous.indexes.contains(index) &&
              !current.indexes.contains(index)) {
            return false;
          }
          return true;
        },
        builder: (context, state) {
          bool isSelected = state.indexes.contains(index);

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                file,
                fit: BoxFit.cover,
              ),
              if (isSelected) _selectionOverlay(),
            ],
          );
        },
      ),
    );
  }

  Widget _selectionOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(.7),
      ),
      child: const Center(
        child: Icon(
          Icons.check_circle,
          color: Colors.white,
          size: 60,
        ),
      ),
    );
  }

  Widget _errorView(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              'Fehler beim Laden der Galerie',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                context.read<GalleryCubit>().loadGallery();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
