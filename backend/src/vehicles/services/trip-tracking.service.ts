import { Injectable, OnModuleInit } from '@nestjs/common';
import { SettingsService } from '../../settings/settings.service';

@Injectable()
export class TripTrackingService implements OnModuleInit {
  // Fuel consumption MPG (configurable, default: 14)
  private fuelConsumptionMpg: number = 14;
  // 1 mile = 1.60934 km
  private readonly KM_PER_MILE = 1.60934;
  // 1 gallon = 3.78541 liters
  private readonly LITERS_PER_GALLON = 3.78541;

  constructor(private readonly settingsService: SettingsService) {}

  async onModuleInit() {
    // Load MPG setting on module initialization
    await this.loadMpgSetting();
  }

  /**
   * Load MPG setting from database
   */
  private async loadMpgSetting(): Promise<void> {
    try {
      const mpg = await this.settingsService.getValue<number>(
        'fuel_consumption_mpg',
        14,
      );
      this.fuelConsumptionMpg = mpg;
      console.log(`[TripTrackingService] Loaded fuel consumption MPG: ${this.fuelConsumptionMpg}`);
    } catch (error) {
      console.warn(
        `[TripTrackingService] Failed to load MPG setting, using default: 14`,
        error,
      );
      this.fuelConsumptionMpg = 14;
    }
  }

  /**
   * Refresh MPG setting from database (useful after admin updates it)
   */
  async refreshMpgSetting(): Promise<void> {
    await this.loadMpgSetting();
  }

  /**
   * Get current MPG value
   */
  getFuelConsumptionMpg(): number {
    return this.fuelConsumptionMpg;
  }

  /**
   * Calculate distance between two coordinates using Haversine formula
   * Returns distance in kilometers
   */
  calculateDistance(
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number,
  ): number {
    const R = 6371; // Earth's radius in kilometers
    const dLat = this.toRadians(lat2 - lat1);
    const dLon = this.toRadians(lon2 - lon1);

    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.toRadians(lat1)) *
        Math.cos(this.toRadians(lat2)) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const distance = R * c;

    return Math.round(distance * 100) / 100; // Round to 2 decimal places
  }

  /**
   * Calculate estimated fuel consumption in liters
   * Based on configurable MPG setting (default: 14 MPG)
   */
  calculateFuelConsumption(distanceKm: number): number {
    // Convert km to miles
    const distanceMiles = distanceKm / this.KM_PER_MILE;

    // Calculate gallons needed using configurable MPG
    const gallonsNeeded = distanceMiles / this.fuelConsumptionMpg;

    // Convert to liters
    const litersNeeded = gallonsNeeded * this.LITERS_PER_GALLON;

    return Math.round(litersNeeded * 100) / 100; // Round to 2 decimal places
  }

  /**
   * Calculate total fuel for both outbound and return legs
   */
  calculateTotalFuelConsumption(outboundKm: number, returnKm: number): {
    outboundFuel: number;
    returnFuel: number;
    totalFuel: number;
  } {
    const outboundFuel = this.calculateFuelConsumption(outboundKm);
    const returnFuel = this.calculateFuelConsumption(returnKm);
    const totalFuel = outboundFuel + returnFuel;

    return {
      outboundFuel: Math.round(outboundFuel * 100) / 100,
      returnFuel: Math.round(returnFuel * 100) / 100,
      totalFuel: Math.round(totalFuel * 100) / 100,
    };
  }

  private toRadians(degrees: number): number {
    return degrees * (Math.PI / 180);
  }
}

