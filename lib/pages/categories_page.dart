import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../services/recipe_service.dart';
import '../widgets/category_icon.dart';
import '../widgets/background_decorations.dart';
import 'category_recipes_page.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<RecipeService>();
    final categories = service.categories;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '全部分类',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: BackgroundDecorations(
        variant: 3,
        child: categories.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 24,
                childAspectRatio: 0.8,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return CategoryIcon(
                  label: cat.name,
                  bgColor: CategoryConfig.getBgColor(cat.id),
                  iconAsset: CategoryConfig.getIconAsset(cat.id),
                  count: cat.total,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryRecipesPage(
                        categoryId: cat.id,
                        categoryName: cat.name,
                      ),
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }
}
