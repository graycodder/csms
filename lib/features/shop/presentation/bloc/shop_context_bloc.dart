import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:csms/features/shop/domain/entities/shop_entity.dart';
import 'package:csms/features/shop/domain/repositories/shop_repository.dart';

abstract class ShopContextEvent extends Equatable {
  const ShopContextEvent();
  @override
  List<Object?> get props => [];
}

class LoadShops extends ShopContextEvent {
  final String ownerId;
  final String shopId;
  final String role;

  const LoadShops({
    required this.ownerId,
    this.shopId = '',
    this.role = '',
  });

  @override
  List<Object?> get props => [ownerId, shopId, role];
}

class SelectShop extends ShopContextEvent {
  final ShopEntity shop;
  final List<ShopEntity> shops;
  const SelectShop(this.shop, this.shops);
  @override
  List<Object?> get props => [shop, shops];
}

class UpdateShop extends ShopContextEvent {
  final ShopEntity shop;
  const UpdateShop(this.shop);
  @override
  List<Object?> get props => [shop];
}

class ResetShopContext extends ShopContextEvent {}

abstract class ShopContextState extends Equatable {
  const ShopContextState();
  @override
  List<Object?> get props => [];
}

class ShopContextInitial extends ShopContextState {}

class ShopContextLoading extends ShopContextState {}

class ShopContextLoaded extends ShopContextState {
  final List<ShopEntity> shops;
  const ShopContextLoaded(this.shops);
  @override
  List<Object?> get props => [shops];
}

class ShopSelected extends ShopContextState {
  final ShopEntity selectedShop;
  final List<ShopEntity> shops;
  const ShopSelected(this.selectedShop, this.shops);
  @override
  List<Object?> get props => [selectedShop, shops];
}

class ShopContextEmpty extends ShopContextState {}

class ShopContextError extends ShopContextState {
  final String message;
  const ShopContextError(this.message);
  @override
  List<Object?> get props => [message];
}

class ShopContextBloc extends Bloc<ShopContextEvent, ShopContextState> {
  final ShopRepository repository;

  ShopContextBloc({required this.repository}) : super(ShopContextInitial()) {
    on<LoadShops>(_onLoadShops);
    on<SelectShop>(_onSelectShop);
    on<UpdateShop>(_onUpdateShop);
    on<ResetShopContext>((event, emit) {
      repository.clearSelectedShopId();
      emit(ShopContextInitial());
    });
  }

  Future<void> _onLoadShops(
    LoadShops event,
    Emitter<ShopContextState> emit,
  ) async {
    emit(ShopContextLoading());
    final result = await repository.getShopsByOwner(event.ownerId);
    result.fold((failure) => emit(ShopContextError(failure.message)), (shops) {
      // Role-based filtering: If not owner, only show assigned shop
      List<ShopEntity> filteredShops = shops;
      if (event.role != 'owner' && event.shopId.isNotEmpty) {
        filteredShops = shops.where((s) => s.shopId == event.shopId).toList();
      }

      if (filteredShops.isEmpty) {
        emit(ShopContextEmpty());
      } else if (filteredShops.length == 1) {
        repository.saveSelectedShopId(filteredShops.first.shopId);
        emit(ShopSelected(filteredShops.first, filteredShops));
      } else {
        // Check for cached shop selection
        final cachedId = repository.getSelectedShopId();
        if (cachedId != null) {
          final cachedShop = filteredShops.cast<ShopEntity?>().firstWhere(
                (s) => s?.shopId == cachedId,
                orElse: () => null,
              );
          if (cachedShop != null) {
            emit(ShopSelected(cachedShop, filteredShops));
            return;
          }
        }
        emit(ShopContextLoaded(filteredShops));
      }
    });
  }

  void _onSelectShop(SelectShop event, Emitter<ShopContextState> emit) {
    repository.saveSelectedShopId(event.shop.shopId);
    
    emit(ShopSelected(event.shop, event.shops));
  }

  Future<void> _onUpdateShop(UpdateShop event, Emitter<ShopContextState> emit) async {
    final currentShops = state is ShopSelected ? (state as ShopSelected).shops : <ShopEntity>[];
    emit(ShopContextLoading());
    final result = await repository.updateShop(event.shop);
    result.fold(
      (failure) => emit(ShopContextError(failure.message)),
      (_) {
        // After successful update, we might want to stay on ShopSelected with new data
        emit(ShopSelected(event.shop, currentShops));
        // And optionally reload to sync the full list
        add(LoadShops(ownerId: event.shop.ownerId));
      },
    );
  }
}
