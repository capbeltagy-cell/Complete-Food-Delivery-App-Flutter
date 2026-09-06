import{BadRequestException,Controller,Get,NotFoundException,Param,Post,Req,Res,UploadedFile,UseGuards,UseInterceptors}from'@nestjs/common';
import{FileInterceptor}from'@nestjs/platform-express';
import{Request,Response}from'express';
import{extname}from'path';
import{randomUUID}from'crypto';
import{memoryStorage}from'multer';
import{GetObjectCommand,HeadBucketCommand,CreateBucketCommand,PutObjectCommand,S3Client}from'@aws-sdk/client-s3';
import{Readable}from'stream';
import{JwtGuard}from'../auth/jwt.guard';
import{JwtUser}from'../auth/auth.types';
import{PrismaService}from'../prisma/prisma.service';

@Controller('uploads')
export class UploadsController{
 private readonly bucket=process.env.MINIO_BUCKET||'dierb-uploads';
 private readonly s3=new S3Client({
  endpoint:`http://${process.env.MINIO_ENDPOINT||'minio'}:${process.env.MINIO_PORT||'9000'}`,
  region:process.env.MINIO_REGION||'us-east-1',
  forcePathStyle:true,
  credentials:{accessKeyId:process.env.MINIO_ACCESS_KEY||'',secretAccessKey:process.env.MINIO_SECRET_KEY||''}
 });
 private bucketReady?:Promise<void>;
 constructor(private readonly p:PrismaService){}
 private ensureBucket(){return this.bucketReady??=this.s3.send(new HeadBucketCommand({Bucket:this.bucket})).then(()=>undefined).catch(async()=>{await this.s3.send(new CreateBucketCommand({Bucket:this.bucket}));});}
 @UseGuards(JwtGuard)
 @Post()
 @UseInterceptors(FileInterceptor('file',{limits:{fileSize:8*1024*1024},fileFilter:(_,file,cb)=>{const ok=file.mimetype.startsWith('image/');cb(ok?null:new BadRequestException('Images only'),ok);},storage:memoryStorage()}))
 async upload(@Req()r:Request&{user:JwtUser},@UploadedFile()file:Express.Multer.File){
  if(!file)throw new BadRequestException('File required');
  await this.ensureBucket();
  const key=`${randomUUID()}${extname(file.originalname).toLowerCase()}`;
  await this.s3.send(new PutObjectCommand({Bucket:this.bucket,Key:key,Body:file.buffer,ContentType:file.mimetype,CacheControl:'public, max-age=31536000, immutable'}));
  const url=`${process.env.PUBLIC_API_URL}/v1/uploads/${key}`;
  return this.p.upload.create({data:{ownerId:r.user.sub,storageKey:key,url,mimeType:file.mimetype,bytes:file.size,purpose:'image'}});
 }
 @Get(':key')
 async download(@Param('key')key:string,@Res()res:Response){
  if(!/^[0-9a-f-]{36}\.[a-z0-9]{2,5}$/i.test(key))throw new NotFoundException();
  const record=await this.p.upload.findUnique({where:{storageKey:key}});
  if(!record||record.deletedAt)throw new NotFoundException();
  try{
   await this.ensureBucket();
   const object=await this.s3.send(new GetObjectCommand({Bucket:this.bucket,Key:key}));
   res.type(record.mimeType).setHeader('Cache-Control','public, max-age=31536000, immutable');
   if(object.ContentLength!=null)res.setHeader('Content-Length',String(object.ContentLength));
   const body=object.Body;
   if(body instanceof Readable)return body.pipe(res);
   if(body&&'transformToByteArray'in body){const bytes=await body.transformToByteArray();return res.send(Buffer.from(bytes));}
   throw new Error('Unsupported object body');
  }catch{throw new NotFoundException();}
 }
}
