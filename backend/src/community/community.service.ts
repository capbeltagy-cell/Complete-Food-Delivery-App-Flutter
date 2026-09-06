import{Injectable,NotFoundException}from'@nestjs/common';import{PrismaService}from'../prisma/prisma.service';import{CreateAnswerDto,CreateQuestionDto,CreateReportDto}from'./dto';
@Injectable()export class CommunityService{constructor(private readonly p:PrismaService){}
 list(cityId:string,cursor?:string){return this.p.question.findMany({where:{cityId,status:'published',deletedAt:null,...(cursor&&{id:{lt:cursor}})},include:{author:{select:{id:true,name:true,role:true,avatarUrl:true}}},orderBy:{createdAt:'desc'},take:30});}
 async details(id:string){const q=await this.p.question.findFirst({where:{id,status:'published',deletedAt:null},include:{author:{select:{id:true,name:true,role:true,avatarUrl:true}},answers:{where:{status:'published'},include:{author:{select:{id:true,name:true,role:true,avatarUrl:true}}},orderBy:{createdAt:'asc'}}}});if(!q)throw new NotFoundException();return q;}
 create(authorId:string,d:CreateQuestionDto){return this.p.question.create({data:{...d,authorId}});}
 answer(authorId:string,questionId:string,d:CreateAnswerDto){return this.p.$transaction(async tx=>{const q=await tx.question.findFirst({where:{id:questionId,status:'published'}});if(!q)throw new NotFoundException();const a=await tx.answer.create({data:{questionId,authorId,body:d.body}});await tx.question.update({where:{id:questionId},data:{answerCount:{increment:1}}});return a;});}
 like(userId:string,questionId:string){return this.p.$transaction(async tx=>{await tx.questionLike.create({data:{questionId,userId}});await tx.question.update({where:{id:questionId},data:{helpfulCount:{increment:1}}});return{success:true};});}
 report(reporterId:string,d:CreateReportDto){return this.p.report.create({data:{...d,reporterId}});}
}
