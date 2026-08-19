import {
  Controller, Get, Post, Patch, Delete, Body, Param, UseGuards, Req, HttpCode, HttpStatus,
  UseInterceptors, UploadedFile, BadRequestException,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { ProductsService } from './products.service';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';

@ApiTags('Products')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('products')
export class ProductsController {
  constructor(private readonly productsService: ProductsService) {}

  @Get()
  findAll() {
    return this.productsService.findAll();
  }

  @Get('my')
  @Roles(UserRole.WHOLESALER)
  findMine(@Req() req: any) {
    return this.productsService.findByWholesaler(req.user.id);
  }

  @Post('upload')
  @Roles(UserRole.WHOLESALER)
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: './uploads',
        filename: (req, file, callback) => {
          const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
          const ext = extname(file.originalname);
          callback(null, `${uniqueSuffix}${ext}`);
        },
      }),
      fileFilter: (req, file, callback) => {
        const ext = extname(file.originalname).toLowerCase();
        const allowedExts = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
        const isAllowedMimetype = file.mimetype && file.mimetype.match(/\/(jpg|jpeg|png|gif|webp)$/);
        const isAllowedExtension = allowedExts.includes(ext);
        
        if (!isAllowedMimetype && !isAllowedExtension) {
          return callback(new BadRequestException('Only image files are allowed!'), false);
        }
        callback(null, true);
      },
      limits: {
        fileSize: 5 * 1024 * 1024, // 5MB limit
      },
    }),
  )
  uploadFile(@UploadedFile() file: any) {
    if (!file) {
      throw new BadRequestException('No file uploaded');
    }
    return {
      filename: file.filename,
      url: `/uploads/${file.filename}`,
    };
  }

  @Get('wholesaler/:wholesalerId')
  findByWholesalerId(@Param('wholesalerId') wholesalerId: string) {
    return this.productsService.findByWholesalerId(wholesalerId);
  }

  @Get('barcode/:barcode')
  findByBarcode(@Param('barcode') barcode: string) {
    return this.productsService.findByBarcode(barcode);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.productsService.findOne(id);
  }

  @Post()
  @Roles(UserRole.WHOLESALER)
  create(@Body() dto: CreateProductDto, @Req() req: any) {
    return this.productsService.create(dto, req.user.id);
  }

  @Patch(':id/stock')
  @Roles(UserRole.WHOLESALER)
  updateStock(
    @Param('id') id: string,
    @Body('quantity') quantity: number,
    @Req() req: any,
  ) {
    return this.productsService.updateStock(id, quantity, req.user.id);
  }

  @Patch(':id')
  @Roles(UserRole.WHOLESALER)
  update(
    @Param('id') id: string,
    @Body() dto: UpdateProductDto,
    @Req() req: any,
  ) {
    return this.productsService.update(id, dto, req.user.id);
  }

  @Delete(':id')
  @Roles(UserRole.WHOLESALER)
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(@Param('id') id: string, @Req() req: any) {
    return this.productsService.remove(id, req.user.id);
  }
}
