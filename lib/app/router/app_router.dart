import 'package:go_router/go_router.dart';
import 'package:laundry_app/features/auth/presentation/pages/login_page.dart';
import 'package:laundry_app/features/auth/presentation/pages/signup_page.dart';
import 'package:laundry_app/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:laundry_app/features/home/presentation/pages/home_page.dart';
import 'package:laundry_app/features/home/presentation/pages/services_page.dart';
import 'package:laundry_app/features/home/presentation/pages/service_detail_page.dart';
import 'package:laundry_app/features/home/presentation/pages/category_detail_page.dart';
import 'package:laundry_app/features/basket/presentation/pages/basket_page.dart';
import 'package:laundry_app/features/basket/presentation/pages/cart_page.dart';
import 'package:laundry_app/features/orders/presentation/pages/orders_page.dart';
import 'package:laundry_app/features/orders/presentation/pages/order_details_page.dart';
import 'package:laundry_app/features/orders/presentation/pages/order_success_page.dart';
import 'package:laundry_app/features/payment/presentation/pages/payment_page.dart';
import 'package:laundry_app/features/profile/presentation/pages/profile_page.dart';
import 'package:laundry_app/features/profile/presentation/pages/addresses_page.dart';
import 'package:laundry_app/features/profile/presentation/pages/edit_address_page.dart';
import 'package:laundry_app/features/profile/presentation/pages/add_address_page.dart';
import 'package:laundry_app/features/profile/presentation/pages/address_list_page.dart';
import 'package:laundry_app/features/common/domain/models/address_model.dart';
import 'package:laundry_app/features/admin/presentation/pages/admin_seed_page.dart';
import 'package:laundry_app/features/admin/presentation/pages/admin_home_page.dart';
import 'package:laundry_app/features/admin/presentation/pages/add_laundry_page.dart';
import 'package:laundry_app/features/admin/presentation/pages/add_service_page.dart';
import 'package:laundry_app/features/admin/presentation/pages/add_service_item_page.dart';
import 'package:laundry_app/features/admin/presentation/pages/add_pricing_page.dart';
import 'package:laundry_app/features/admin/presentation/pages/model_details_page.dart';
import 'package:laundry_app/features/admin/presentation/pages/create_admin_page.dart';
import 'package:laundry_app/features/common/presentation/pages/splash_page.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupPage(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/',
      redirect: (context, state) => '/home',
    ),
                GoRoute(
                  path: '/laundry/:laundryId',
                  builder: (context, state) {
                    final id = state.pathParameters['laundryId']!;
                    return ServicesPage(laundryId: id);
                  },
                ),
                GoRoute(
                  path: '/services/all',
                  builder: (context, state) {
                    // Show all service categories (no specific laundry)
                    return ServicesPage(laundryId: 'all');
                  },
                ),
    GoRoute(
      path: '/service/:serviceId',
      builder: (context, state) {
        final id = state.pathParameters['serviceId']!;
        return ServiceDetailPage(serviceId: id);
      },
    ),
    GoRoute(
      path: '/category/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return CategoryDetailPage(categoryId: id);
      },
    ),
    GoRoute(
      path: '/cart',
      builder: (context, state) => const CartPage(),
    ),
    GoRoute(
      path: '/basket',
      builder: (context, state) => const BasketPage(),
    ),
    GoRoute(
      path: '/payment',
      builder: (context, state) {
        final amount = double.tryParse(state.uri.queryParameters['amount'] ?? '0') ?? 0.0;
        return PaymentPage(totalAmount: amount);
      },
    ),
    GoRoute(
      path: '/orders',
      builder: (context, state) => const OrdersPage(),
    ),
    GoRoute(
      path: '/order/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return OrderDetailsPage(orderId: id);
      },
    ),
    GoRoute(
      path: '/order/success/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return OrderSuccessPage(orderId: id);
      },
    ),
    GoRoute(
      path: '/orders/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return OrderDetailsPage(orderId: id);
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: '/addresses',
      builder: (context, state) => const AddressesPage(),
    ),
    GoRoute(
      path: '/addresses/edit',
      builder: (context, state) {
        final address = state.extra as AddressModel?;
        return EditAddressPage(address: address);
      },
    ),
    GoRoute(
      path: '/addresses/add',
      builder: (context, state) => const AddAddressPage(),
    ),
    GoRoute(
      path: '/addresses/list',
      builder: (context, state) => const AddressListPage(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminHomePage(),
    ),
    GoRoute(
      path: '/admin/seed',
      builder: (context, state) => const AdminSeedPage(),
    ),
    GoRoute(
      path: '/admin/add-laundry',
      builder: (context, state) => const AddLaundryPage(),
    ),
    GoRoute(
      path: '/admin/add-service',
      builder: (context, state) => const AddServicePage(),
    ),
    GoRoute(
      path: '/admin/add-service-item',
      builder: (context, state) => const AddServiceItemPage(),
    ),
    GoRoute(
      path: '/admin/add-pricing',
      builder: (context, state) => const AddPricingPage(),
    ),
    GoRoute(
      path: '/admin/model-details',
      builder: (context, state) {
        final modelType = state.uri.queryParameters['type'] ?? 'laundry';
        return ModelDetailsPage(modelType: modelType);
      },
    ),
    GoRoute(
      path: '/admin/create-admin',
      builder: (context, state) => const CreateAdminPage(),
    ),
  ],
);

