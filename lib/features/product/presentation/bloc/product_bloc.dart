import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import 'package:csms/features/product/domain/entities/product_entity.dart';
import 'package:csms/features/product/domain/repositories/product_repository.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class ProductEvent extends Equatable {
  const ProductEvent();
  @override
  List<Object?> get props => [];
}

class LoadProducts extends ProductEvent {
  final String shopId;
  final String ownerId;
  const LoadProducts({required this.shopId, required this.ownerId});
  @override
  List<Object?> get props => [shopId, ownerId];
}

class AddProduct extends ProductEvent {
  final String ownerId;
  final ProductEntity product;
  const AddProduct({required this.ownerId, required this.product});
  @override
  List<Object?> get props => [ownerId, product];
}

class UpdateProduct extends ProductEvent {
  final String ownerId;
  final ProductEntity product;
  const UpdateProduct({required this.ownerId, required this.product});
  @override
  List<Object?> get props => [ownerId, product];
}

class ResetProduct extends ProductEvent {}


// ─── States ──────────────────────────────────────────────────────────────────

abstract class ProductState extends Equatable {
  const ProductState();
  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductOperationInProgress extends ProductState {}

class ProductLoaded extends ProductState {
  final List<ProductEntity> products;
  const ProductLoaded(this.products);
  @override
  List<Object?> get props => [products];
}

class ProductError extends ProductState {
  final String message;
  const ProductError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── Bloc ─────────────────────────────────────────────────────────────────────

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository repository;

  ProductBloc({required this.repository}) : super(ProductInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<AddProduct>(_onAddProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<ResetProduct>((event, emit) => emit(ProductInitial()));
  }

  Future<void> _onLoadProducts(
      LoadProducts event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    await emit.forEach<ProductState>(
      repository.getProducts(event.shopId, event.ownerId).map((result) {
        return result.fold(
          (failure) => ProductError(failure.message),
          (products) {
            // Sort new first
            products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return ProductLoaded(products);
          },
        );
      }),
      onData: (state) => state,
    );
  }

  Future<void> _onAddProduct(
      AddProduct event, Emitter<ProductState> emit) async {
    emit(ProductOperationInProgress());
    final result = await repository.addProduct(event.product);
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (_) => null,
    );
    // No need to manually load, stream will update
  }

  Future<void> _onUpdateProduct(
      UpdateProduct event, Emitter<ProductState> emit) async {
    emit(ProductOperationInProgress());
    final result = await repository.updateProduct(event.product);
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (_) => null,
    );
    // No need to manually load, stream will update
  }

}
