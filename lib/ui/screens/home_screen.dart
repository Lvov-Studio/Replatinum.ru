import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/category_provider.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/banner_slider.dart';
import 'product_search_delegate.dart';
import 'main_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Инициализируем загрузку категорий при первом запуске экрана
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Строка поиска
            Container(
              color: AppColors.darkAccent,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: GestureDetector(
                onTap: () {
                  showSearch(
                    context: context,
                    delegate: ProductSearchDelegate(),
                  );
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Поиск по каталогу...',
                          style: TextStyle(color: AppColors.secondaryText, fontSize: 16),
                        ),
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent,
                          borderRadius: BorderRadius.circular(8), // Скругление как у кнопки
                        ),
                        child: const Icon(Icons.search, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Слайдер с баннерами
            const SizedBox(height: 16),
            const BannerSlider(),
            
            // Заголовок категорий
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Text(
                'Популярные категории',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mainText,
                ),
              ),
            ),

            // Горизонтальная лента категорий
            SizedBox(
              height: 110,
              child: Consumer<CategoryProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.error.isNotEmpty) {
                    return Center(
                      child: ElevatedButton(
                        onPressed: () => provider.fetchCategories(),
                        child: const Text('Повторить'),
                      ),
                    );
                  }

                  if (provider.categories.isEmpty) {
                    return const Center(child: Text('Категории не найдены'));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: provider.categories.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final category = provider.categories[index];
                      return GestureDetector(
                        onTap: () {
                          // Переключаемся на вкладку Каталог (индекс 1)
                          MainScreen.of(context)?.switchToTab(1);
                        },
                        child: SizedBox(
                          width: 80,
                          child: Column(
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: AppColors.primaryAccent,
                                    width: 2,
                                  ),
                                ),
                                padding: const EdgeInsets.all(4), // Отступ между рамкой и картинкой
                                child: Container(
                                  clipBehavior: Clip.antiAlias,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: category.image.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: category.image,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => const Center(
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                          errorWidget: (context, url, error) => const Icon(
                                            Icons.image_not_supported,
                                            color: AppColors.secondaryText,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.category,
                                          color: AppColors.secondaryText,
                                        ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                category.name,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.mainText,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            
            const SizedBox(height: 24), // Отступ снизу
          ],
        ),
      ),
    );
  }
}
