import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export interface LatLng { lat: number; lng: number; }
export interface RouteResult {
  distanceKm: number;
  durationMinutes: number;
  polyline: string;
}

/**
 * MapsService - Google Maps Platform (Stub)
 * Replace the stub methods with actual Google Maps client once
 * GOOGLE_MAPS_API_KEY is configured in .env
 */
@Injectable()
export class MapsService {
  private readonly logger = new Logger(MapsService.name);

  constructor(private readonly cfg: ConfigService) {}

  async getRoute(origin: LatLng, destination: LatLng): Promise<RouteResult> {
    this.logger.log(`[STUB] Route from (${origin.lat},${origin.lng}) to (${destination.lat},${destination.lng})`);

    // TODO: Replace with @googlemaps/google-maps-services-js:
    // const client = new Client();
    // const res = await client.directions({ params: { origin, destination, key: this.cfg.get('GOOGLE_MAPS_API_KEY') } });

    // Stub: calculate a rough straight-line distance
    const R = 6371;
    const dLat = ((destination.lat - origin.lat) * Math.PI) / 180;
    const dLng = ((destination.lng - origin.lng) * Math.PI) / 180;
    const a =
      Math.sin(dLat / 2) ** 2 +
      Math.cos((origin.lat * Math.PI) / 180) *
        Math.cos((destination.lat * Math.PI) / 180) *
        Math.sin(dLng / 2) ** 2;
    const distanceKm = R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return {
      distanceKm: Math.round(distanceKm * 10) / 10,
      durationMinutes: Math.round(distanceKm * 2.5),
      polyline: 'stub_encoded_polyline',
    };
  }

  async geocode(address: string): Promise<LatLng> {
    this.logger.log(`[STUB] Geocoding: "${address}"`);
    // Stub: return a fixed coordinate (Bangalore city center)
    return { lat: 12.9716, lng: 77.5946 };
  }

  async reverseGeocode(lat: number, lng: number): Promise<string> {
    this.logger.log(`[STUB] Reverse Geocoding: (${lat}, ${lng})`);
    // Stub: return a clean simulated address based on coordinates
    return `ZoneSupply Shop, near MG Road, Bangalore 560001 (Lat: ${lat.toFixed(4)}, Lng: ${lng.toFixed(4)})`;
  }
}
