import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import 'package:csms/features/shop/domain/entities/shop_entity.dart';
import 'package:csms/features/shop/domain/repositories/shop_repository.dart';
import 'package:csms/core/error/failures.dart';

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

    await emit.forEach<Either<Failure, List<ShopEntity>>>(
      repository.getShopsByOwner(event.ownerId),
      onData: (result) {
        return result.fold(
          (failure) => ShopContextError(failure.message),
          (shops) {
            // Role-based filtering: If not owner, only show assigned shop
            List<ShopEntity> filteredShops = shops;
            if (event.role != 'owner' && event.shopId.isNotEmpty) {
              filteredShops = shops.where((s) => s.shopId == event.shopId).toList();
            }

            if (filteredShops.isEmpty) {
              return ShopContextEmpty();
            }

            // Determine which shop should be selected
            String? shopIdToSelect;
            
            // 1. If currently selected, stay on it (fetch latest data from list)
            final currentState = state;
            if (currentState is ShopSelected) {
              shopIdToSelect = currentState.selectedShop.shopId;
            } 
            // 2. Otherwise check cached ID
            else {
              shopIdToSelect = repository.getSelectedShopId();
            }
            
            // 3. Fallback to first shop if only one exists or no valid selection
            if (shopIdToSelect == null && filteredShops.length == 1) {
              shopIdToSelect = filteredShops.first.shopId;
            }

            if (shopIdToSelect != null) {
              final selectedShop = filteredShops.cast<ShopEntity?>().firstWhere(
                    (s) => s?.shopId == shopIdToSelect,
                    orElse: () => null,
                  );
              if (selectedShop != null) {
                repository.saveSelectedShopId(selectedShop.shopId);
                return ShopSelected(selectedShop, filteredShops);
              }
            }

            return ShopContextLoaded(filteredShops);
          },
        );
      },
    );
  }

  void _onSelectShop(SelectShop event, Emitter<ShopContextState> emit) {
    repository.saveSelectedShopId(event.shop.shopId);
    emit(ShopSelected(event.shop, event.shops));
  }

  Future<void> _onUpdateShop(UpdateShop event, Emitter<ShopContextState> emit) async {
    final result = await repository.updateShop(event.shop);
    result.fold(
      (failure) => emit(ShopContextError(failure.message)),
      (_) {
        // Emit the updated shop explicitly so that UI listeners (e.g. ShopEditPage)
        // receive a state change and can close their LoadingOverlay.
        if (state is ShopSelected) {
          final curState = state as ShopSelected;
          emit(ShopSelected(event.shop, curState.shops));
        } else if (state is ShopContextLoaded) {
          final curState = state as ShopContextLoaded;
          emit(ShopContextLoaded(curState.shops.map((s) => s.shopId == event.shop.shopId ? event.shop : s).toList()));
        }
      },
    );
  }
}
