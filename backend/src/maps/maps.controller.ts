import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { MapsService } from './maps.service';

@ApiTags('Maps')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('maps')
export class MapsController {
  constructor(private readonly mapsService: MapsService) {}

  @Get('route')
  getRoute(
    @Query('originLat') originLat: string,
    @Query('originLng') originLng: string,
    @Query('destLat') destLat: string,
    @Query('destLng') destLng: string,
  ) {
    return this.mapsService.getRoute(
      { lat: +originLat, lng: +originLng },
      { lat: +destLat, lng: +destLng },
    );
  }

  @Get('geocode')
  geocode(@Query('address') address: string) {
    return this.mapsService.geocode(address);
  }

  @Get('reverse-geocode')
  reverseGeocode(@Query('lat') lat: string, @Query('lng') lng: string) {
    return this.mapsService.reverseGeocode(+lat, +lng);
  }
}
