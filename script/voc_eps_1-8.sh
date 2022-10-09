# NEED TO SET
DATASET_ROOT=../../dataset/VOC/VOCdevkit/VOC2012
WEIGHT_ROOT=./pretrained
SALIENCY_ROOT=SALImages
GPU=0,1,2,3

# Default setting
SESSION="eps_1-8(0)"
DATASET="voc12"
BACKBONE="resnet38_eps"
SPLIT="1_8"
SPLIT_NUM="0"
# Paths
IMG_ROOT=${DATASET_ROOT}/JPEGImages
SAL_ROOT=${DATASET_ROOT}/${SALIENCY_ROOT}
BASE_WEIGHT=${WEIGHT_ROOT}/ilsvrc-cls_rna-a1_cls1000_ep-0001.params
LB_DATA_LIST=data/${DATASET}/split/${SPLIT}/lb_train_${SPLIT_NUM}.txt ############
ULB_DATA_LIST=data/${DATASET}/split/${SPLIT}/ulb_train_${SPLIT_NUM}.txt #########


# train classification network with EPS
CUDA_VISIBLE_DEVICES=${GPU} python3 contrast_train.py \
    --train_list        ${LB_DATA_LIST} \
    --train_ulb_list    ${ULB_DATA_LIST} \
    --session           ${SESSION} \
    --network           network.${BACKBONE} \
    --data_root         ${IMG_ROOT} \
    --saliency_root     ${SAL_ROOT} \
    --weights           ${BASE_WEIGHT} \
    --resize_size       256 512 \
    --crop_size         448 \
    --tau               0.4 \
    --max_iters         10000 \
    --iter_size         1 \
    --batch_size        8


# 2. inference CAM (train/train_aug/val)
TRAINED_WEIGHT=train_log/${SESSION}/checkpoint_cls.pth
DATA=train_aug
CUDA_VISIBLE_DEVICES=${GPU} python3 contrast_infer.py \
    --infer_list ${LB_DATA_LIST} \
    --img_root ${IMG_ROOT} \
    --network network.${BACKBONE} \
    --weights ${TRAINED_WEIGHT} \
    --thr 0.20 \
    --n_gpus 4 \
    --n_processes_per_gpu 1 1 1 1 \
    --cam_png train_log/${SESSION}/result/cam_png \
    --cam_npy train_log/${SESSION}/result/cam_npy \
    --crf train_log/${SESSION}/result/crf_png\
    --crf_t 5 \
    --crf_alpha 8
# unlabeled
CUDA_VISIBLE_DEVICES=${GPU} python3 contrast_infer.py \
    --infer_list ${ULB_DATA_LIST} \
    --img_root ${IMG_ROOT} \
    --network network.${BACKBONE} \
    --weights ${TRAINED_WEIGHT} \
    --thr 0.22 \
    --n_gpus 4 \
    --n_processes_per_gpu 1 1 1 1 \
    --cam_png train_log/${SESSION}/result/cam_png \
    --cam_npy train_log/${SESSION}/result/cam_npy \
    --is_unlabeled \
    --pl_method all \
    --crf train_log/${SESSION}/result/crf_png \
    --crf_t 5 \
    --crf_alpha 8 \


# 3. evaluate CAM
GT_ROOT=${DATASET_ROOT}/SegmentationClassAug/
echo TRAIN
CUDA_VISIBLE_DEVICES=${GPU} python3 eval.py \
    --list data/voc12/train_id.txt \
    --predict_dir train_log/${SESSION}/result/cam_npy/ \
    --gt_dir ${GT_ROOT} \
    --comment $SESSION \
    --logfile train_log/${SESSION}/result/lb_train.txt \
    --max_th 30 \
    --type npy \
    --curve
# echo LABELED
# CUDA_VISIBLE_DEVICES=${GPU} python3 eval.py \
#     --list ${LB_DATA_LIST} \
#     --predict_dir train_log/${SESSION}/result/cam_npy/ \
#     --gt_dir ${GT_ROOT} \
#     --comment $SESSION \
#     --logfile train_log/${SESSION}/result/lb_train.txt \
#     --max_th 30 \
#     --type npy \
#     --curve
# echo UNLABELED
# CUDA_VISIBLE_DEVICES=${GPU} python3 eval.py \
#     --list ${ULB_DATA_LIST} \
#     --predict_dir train_log/${SESSION}/result/cam_npy/ \
#     --gt_dir ${GT_ROOT} \
#     --comment $SESSION \
#     --logfile train_log/${SESSION}/result/ulb_train.txt \
#     --max_th 25 \
#     --type npy \
#     --curve
#     # Use curve when type=npy
#     #--list data/voc12/${DATA}.txt \


# 4. Generate Segmentation pseudo label
python pseudo_label_gen.py \
    --datalist data/voc12/${DATA}_id.txt \
    --crf_pred train_log/${SESSION}/result/crf_png/crf_5_8 \
    --label_save_dir train_log/${SESSION}/result/crf_seg
